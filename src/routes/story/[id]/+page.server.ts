//import { deleteStorychema } from '@/schemas/story';
import { deleteStorySchema, unpublishStorySchema, toggleStoryLikeSchema } from '@/schemas/story';
import type { ModerationInfo, Story } from '@/types/types';
import { handleFormAction } from '@/utils';
import { error, fail, redirect } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';
import { superValidate } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';

export const load = async (event) => {
	const { user } = await event.parent();

	async function getStory(id: string): Promise<Story> {
		const { data: story, error: storyError } = await event.locals.supabase
			.from('story_view')
			.select('*')
			.eq('id', id)
			.single();

		if (storyError) {
			const errorMessage = `Error fetching story ${id}, please try again later.`;
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return story as Story;
	}

	async function getStoryModeration(id: string): Promise<ModerationInfo[]> {
		const { data: moderation, error: moderationError } = await event.locals.supabase
			.from('story_moderation')
			.select('*')
			.eq('story_id', id);

		if (moderationError) {
			const errorMessage = 'Error fetching moderation, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return moderation;
	}

	function getUserPermission() {
		return user ? user.role !== 'user' : false;
	}

	async function getLikeCount(id: string): Promise<{ count: number; userLiked: boolean }> {
			const { data: liked, error: interestedError } = await event.locals.supabase
				.rpc('get_story_like_count', {
					story_id: parseInt(id),
					user_id: user?.id,
				})
				.single();
	
			if (interestedError) {
				const errorMessage = 'Error fetching interest count, please try again later.';
				setFlash({ type: 'error', message: errorMessage }, event.cookies);
				return error(500, errorMessage);
			}
			return { count: liked.count, userLiked: liked.has_liked };
		}
	
		const likeCount = await getLikeCount(event.params.id);

	return {
		story: await getStory(event.params.id),
		moderation: await getStoryModeration(event.params.id),
		permission: await getUserPermission(),
		likeCount: likeCount.count,
		deleteForm: await superValidate(zod(deleteStorySchema), {
			id: 'delete-story',
		}),
		unpublishForm: await superValidate(zod(unpublishStorySchema), {
			id: 'unpublish-story',
		}),
		toggleLikeForm: await superValidate(
					{ value: likeCount.userLiked },
					zod(toggleStoryLikeSchema),
					{
						id: 'toggle-story-like',
					}
				),
	};
};

export const actions = {
	delete: async (event) =>
		handleFormAction(event, deleteStorySchema, 'delete-story', async (event, userId, form) => {
			const { error: supabaseError2 } = await event.locals.supabase
				.from('map_pins')
				.delete()
				.eq('story_id', form.data.id);

			if (supabaseError2) {
				setFlash({ type: 'error', message: supabaseError2.message }, event.cookies);
				return fail(500, { message: supabaseError2.message, form });
			}
			
			const { error: supabaseError } = await event.locals.supabase
				.from('story')
				.delete()
				.eq('id', form.data.id);

			if (supabaseError) {
				setFlash({ type: 'error', message: supabaseError.message }, event.cookies);
				return fail(500, { message: supabaseError.message, form });
			}

			return redirect(303, '/story');
		}),
	unpublish: async (event) =>
		handleFormAction(
			event,
			unpublishStorySchema,
			'unpublish-story',
			async (event, userId, form) => {
				const { error: supabaseModerationError } = await event.locals.supabase
					.from('story_moderation')
					.update({ status: 'pending', comment: 'Pending moderation' })
					.eq('story_id', form.data.id);

				if (supabaseModerationError) {
					setFlash({ type: 'error', message: supabaseModerationError.message }, event.cookies);
					return fail(500, { message: supabaseModerationError.message, form });
				}

				const { data: storyPin, error: pinsError } = await event.locals.supabase
						.from('map_pins_view')
						.select('id')
						.eq('story_id', form.data.id)
						.maybeSingle();
							
					if (pinsError) {
						console.log(pinsError.message);

						return fail(500, { message: pinsError.message });
					}

					if (storyPin){
						const { error: supabaseModerationError2 } = await event.locals.supabase
							.from('map_pins_moderation')
							.update({ status: 'pending', comment: 'Pending moderation' })
							.eq('map_pin_id', storyPin.id);
	
						if (supabaseModerationError2) {
							console.log(supabaseModerationError2.message);
							return fail(500, { message: supabaseModerationError2.message });
						}
					}

				return redirect(303, '/story');
			}
		),
	toggleLike: async (event) =>
			handleFormAction(
				event,
				toggleStoryLikeSchema,
				'toggle-story-like',
				async (event, userId, form) => {
					if (form.data.value) {
						const { error: supabaseError } = await event.locals.supabase
							.from('liked_stories')
							.insert([
								{
									story_id: parseInt(event.params.id),
									user_id: userId,
								},
							]);
	
						if (supabaseError) {
							setFlash({ type: 'error', message: supabaseError.message }, event.cookies);
							return fail(500, { message: supabaseError.message, form });
						}
					} else {
						const { error: supabaseError } = await event.locals.supabase
							.from('liked_stories')
							.delete()
							.eq('story_id', parseInt(event.params.id))
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
