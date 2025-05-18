import { deleteHowToSchema, toggleHowToUsefulSchema } from '@/schemas/how-to';
import type { HowToWithAuthor, ModerationInfo } from '@/types/types';
import { handleFormAction } from '@/utils';
import { error, fail, redirect } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';
import { superValidate } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';

export const load = async (event) => {
	const { user } = await event.locals.safeGetSession();

	async function getHowTo(id: string): Promise<HowToWithAuthor> {
		const { data: howTo, error: howToError } = await event.locals.supabase
			.from('howtos_view')
			.select('*, author:profiles_view!inner(*)')
			.eq('id', id)
			.single();

		if (howToError) {
			const errorMessage = 'Error fetching how to, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		const image = event.locals.supabase.storage.from('howtos').getPublicUrl(howTo.image);
		const stepsWithImageUrl = howTo.steps.map((step) => {
			const stepImage = event.locals.supabase.storage.from('howtos').getPublicUrl(step.image);
			return { ...step, image: stepImage.data.publicUrl };
		});
		return { ...howTo, image: image.data.publicUrl, steps: stepsWithImageUrl };
	}

	async function getHowToModeration(id: string): Promise<ModerationInfo[]> {
		const { data: moderation, error: moderationError } = await event.locals.supabase
			.from('howtos_moderation')
			.select('*')
			.eq('howto_id', id)
			.order('inserted_at', { ascending: false });

		if (moderationError) {
			const errorMessage = 'Error fetching moderation, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return moderation;
	}

	async function getUsefulCount(id: string): Promise<{ count: number; userUseful: boolean }> {
		const { data: usefuls, error: usefulsError } = await event.locals.supabase
			.rpc('get_howto_useful_count', {
				howto_id: parseInt(id),
				user_id: user?.id,
			})
			.single();

		if (usefulsError) {
			const errorMessage = 'Error fetching useful count, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}
		return { count: usefuls.count, userUseful: usefuls.has_useful };
	}

	const usefulCount = await getUsefulCount(event.params.id);

	return {
		howTo: await getHowTo(event.params.id),
		moderation: await getHowToModeration(event.params.id),
		usefulCount: usefulCount.count,
		deleteForm: await superValidate(zod(deleteHowToSchema), {
			id: 'delete-howto',
		}),
		toggleUsefulForm: await superValidate(
			{ value: usefulCount.userUseful },
			zod(toggleHowToUsefulSchema),
			{
				id: 'toggle-howto-useful',
			}
		),
	};
};

export const actions = {
	delete: async (event) =>
		handleFormAction(event, deleteHowToSchema, 'delete-howto', async (event, userId, form) => {
			const { error: supabaseError } = await event.locals.supabase
				.from('howtos')
				.delete()
				.eq('id', form.data.id);

			if (supabaseError) {
				setFlash({ type: 'error', message: supabaseError.message }, event.cookies);
				return fail(500, { message: supabaseError.message, form });
			}

			return redirect(303, '/how-to');
		}),

	toggleUseful: async (event) =>
		handleFormAction(
			event,
			toggleHowToUsefulSchema,
			'toggle-howto-useful',
			async (event, userId, form) => {
				if (form.data.value) {
					const { error: supabaseError } = await event.locals.supabase
						.from('howtos_useful')
						.insert([
							{
								howto_id: parseInt(event.params.id),
								user_id: userId,
							},
						]);

					if (supabaseError) {
						setFlash({ type: 'error', message: supabaseError.message }, event.cookies);
						return fail(500, { message: supabaseError.message, form });
					}
				} else {
					const { error: supabaseError } = await event.locals.supabase
						.from('howtos_useful')
						.delete()
						.eq('howto_id', parseInt(event.params.id))
						.eq('user_id', userId);

					if (supabaseError) {
						setFlash({ type: 'error', message: supabaseError.message }, event.cookies);
						return fail(500, { message: supabaseError.message, form });
					}
				}

				return { form };
			}
		),
};
