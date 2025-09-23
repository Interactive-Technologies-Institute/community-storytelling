import { createStorySchema } from '$lib/schemas/story';
import { handleFormAction, handleSignInRedirect } from '@/utils';
import { fail, redirect, error } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';
import { superValidate, withFiles } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';

export const load = async (event) => {
	const { session } = await event.locals.safeGetSession();
	const { user } = await event.parent();

	async function getUsers(): Promise<{ id: string; display_name: string }[]> {
		const { data: users, error: usersError } = await event.locals.supabase
		.from('profiles_view')
		.select('id, display_name')
		.neq('id', user?.id);

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

	const form = await superValidate(zod(createStorySchema), { id: 'create-story' });

	form.data.extra = { users: await getUsers() };

	return {
		createForm: form
	};
};

export const actions = {
	createStory: async (event) =>
		handleFormAction(event, createStorySchema, 'create-story', async (event, userId, form) => {
			const { data: storyInsert, error: supabaseError } = await event.locals.supabase
				.from('story')
				.insert({ 
					storyteller: form.data.storyteller, 
					tags: form.data.tags, 
					role: form.data.role, 
					image: form.data.image, 
					user_id: userId, 
					recording_link: form.data.recording_link ?? '', 
					coauthors: form.data.coauthors,
				})
				.select('id')
				.single();

			if (supabaseError) {
				setFlash({ type: 'error', message: supabaseError.message }, event.cookies);
				return fail(500, withFiles({ message: supabaseError.message, form }));
			}

			if (form.data.lat) {
				const { error: locationError } = await event.locals.supabase
					.from('map_pins').insert({
					story_id: storyInsert.id,
					user_id: userId,
					lat: form.data.lat,
					lng: form.data.lng,
					year: form.data.tags[0],
					pin_color: form.data.pinColor
				});
			
				if (locationError) {
					setFlash({ type: 'error', message: locationError.message }, event.cookies);
					return fail(500, withFiles({ message: locationError.message, form }));
				}
			}

			return redirect(303, '/story');
		}),
};
