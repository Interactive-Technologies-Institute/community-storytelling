import { editStorySchema } from '$lib/schemas/edit-story.js';
import { handleFormAction, handleSignInRedirect } from '@/utils';
import { fail, redirect, error } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';
import { superValidate, withFiles } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';

export const load = async (event) => {
	const { session } = await event.locals.safeGetSession();

	async function getUsers(): Promise<{ id: string; display_name: string }[]> {
		const { data: users, error: usersError } = await event.locals.supabase
			.from('profiles_view')
			.select('id, display_name');

		if (usersError) {
			const errorMessage = 'Error fetching users, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return users || [];
	}

	if (!session) {
		return redirect(302, handleSignInRedirect(event));
	}

	const { id } = event.params;
	const { data: story, error: storyError } = await event.locals.supabase
		.from('story_view')
		.select('id, storyteller, tags, coauthors, map_pins(lat, lng, pin_color)')
		.eq('id', id)
		.single();

	if (storyError || !story) {
		throw error(404, 'História não encontrada');
	}

	const form = await superValidate(zod(editStorySchema), { id: 'edit-story' });

	form.data = {
        storyteller: story.storyteller ?? '',
		tags: story.tags?.length === 2 ? story.tags : ['', ''],
        lat: story.map_pins?.[0]?.lat ?? null,
        lng: story.map_pins?.[0]?.lng ?? null,
        pinColor: story.map_pins?.[0]?.pin_color ?? '#ff0000',
        coauthors: story.coauthors ?? [],
        extra: { users: await getUsers() },
        transcription: ''
    };

	return {
		editForm: form
	};
};

export const actions = {
	editStory: async (event) =>
		handleFormAction(event, editStorySchema, 'edit-story', async (event, userId, form) => {
			const { id } = event.params;

			const { error: storyError } = await event.locals.supabase
				.from('story')
				.update({
					storyteller: form.data.storyteller,
					coauthors: form.data.coauthors
				})
				.eq('id', id);

			if (storyError) {
				setFlash({ type: 'error', message: storyError.message }, event.cookies);
				return fail(500, withFiles({ message: storyError.message, form }));
			}

			if (form.data.lat && form.data.lng) {
				const { error: locationError } = await event.locals.supabase
					.from('map_pins')
					.update({
						lat: form.data.lat,
						lng: form.data.lng,
						pin_color: form.data.pinColor
					})
					.eq('story_id', id);

				if (locationError) {
					setFlash({ type: 'error', message: locationError.message }, event.cookies);
					return fail(500, withFiles({ message: locationError.message, form }));
				}
			}

			return redirect(303, `/story/${id}`);
		})
};
