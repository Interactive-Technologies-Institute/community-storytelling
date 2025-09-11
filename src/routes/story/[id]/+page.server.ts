import { deleteStorySchema, unpublishStorySchema, toggleStoryLikeSchema } from '@/schemas/story';
import type { ModerationInfo, Story, UserProfile } from '@/types/types';
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

		if (storyError || !story) {
			const errorMessage = `Error fetching story ${id}, please try again later.`;
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			throw error(500, errorMessage);
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
			throw error(500, errorMessage);
		}

		return moderation;
	}

	async function normalizeProfile(profile: any, userId?: string) {
		let avatarUrl = '';
		if (profile.avatar) {
			avatarUrl =
				event.locals.supabase.storage.from('users').getPublicUrl(profile.avatar).data
					.publicUrl ?? '';
		}

		if (userId && profile.id === userId) {
			profile.id = 'me';
		}

		return { ...profile, avatarUrl };
	}

	async function getUserProfile(storyId: string) {
		const story = await getStory(storyId);

		const { data: userProfile, error: profileError } = await event.locals.supabase
			.from('profiles_view')
			.select('*')
			.eq('id', story.user_id)
			.single();

		if (profileError || !userProfile) {
			const errorMessage = `Error fetching profile, please try again later.`;
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			throw error(500, errorMessage);
		}

		return normalizeProfile(userProfile, user?.id);
	}

	async function getCoauthorProfiles(ids: string[], currentUserId?: string) {
		if (!ids || ids.length === 0) return {};

		const { data: profiles, error: profilesError } = await event.locals.supabase
			.from('profiles_view')
			.select('*')
			.in('id', ids);

		if (profilesError) {
			const errorMessage = 'Error fetching coauthor profiles, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			throw error(500, errorMessage);
		}

		const withAvatars = await Promise.all(
			profiles.map((profile) => normalizeProfile(profile, currentUserId))
		);

		return Object.fromEntries(withAvatars.map((p) => [p.id, p]));
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
			throw error(500, errorMessage);
		}

		return { count: liked.count, userLiked: liked.has_liked };
	}

	const story = await getStory(event.params.id);

	let colinkedStories: Record<number, { id: number; title: string }> = {};
	if (story.colinked_stories && story.colinked_stories.length > 0) {
		const { data: colinkedData, error: colinkedError } = await event.locals.supabase
			.from('story_view')
			.select('id, title')
			.in('id', story.colinked_stories);

		if (!colinkedError && colinkedData) {
			colinkedData.forEach((s) => {
				if (s.id !== null && s.title !== null) {
					colinkedStories[s.id] = { id: s.id, title: s.title };
				}
			});
		}
	}

	const coauthors = await getCoauthorProfiles(story.coauthors ?? [], user?.id);
	const likeCount = await getLikeCount(event.params.id);

	return {
		story,
		moderation: await getStoryModeration(event.params.id),
		profile: await getUserProfile(event.params.id),
		coauthors,
		colinkedStories,
		permission: getUserPermission(),
		likeCount: likeCount.count,
		deleteForm: await superValidate(zod(deleteStorySchema), { id: 'delete-story' }),
		unpublishForm: await superValidate(zod(unpublishStorySchema), { id: 'unpublish-story' }),
		toggleLikeForm: await superValidate(
			{ value: likeCount.userLiked },
			zod(toggleStoryLikeSchema),
			{ id: 'toggle-story-like' }
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
