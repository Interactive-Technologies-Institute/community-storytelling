import type { Story } from '$lib/types/types';
import { error } from '@sveltejs/kit';
import { redirect } from '@sveltejs/kit';

export const load = async (event) => {
	const dataParam = event.url.searchParams.get('data');
	if (!dataParam) {
		throw error(400, 'Missing data param');
	}

	let parsed: { requested_story_id: string; requester_story_id: string };
	try {
		parsed = JSON.parse(decodeURIComponent(dataParam));
	} catch {
		throw error(400, 'Invalid data param');
	}

	const getStory = async (id: string): Promise<Story> => {
		const { data: story, error: storyError } = await event.locals.supabase
			.from('story_view')
			.select('id, title, pub_story_text')
			.eq('id', id)
			.single();

		if (storyError || !story) {
			throw error(500, `Error fetching story ${id}`);
		}

		return story as Story;
	};

	const requestedStory = await getStory(parsed.requested_story_id);
	const requesterStory = await getStory(parsed.requester_story_id);

	return {
		requestedStory,
		requesterStory
	};
};

export const actions = {
	acceptColink: async (event) => {
		const formData = await event.request.formData();
		const requestedStoryId = formData.get('requestedStoryId') as string;
		const requesterStoryId = formData.get('requesterStoryId') as string;

		if (!requestedStoryId || !requesterStoryId) {
			return { success: false, message: 'Missing story IDs' };
		}

		const updateColinkedStories = async (storyId: string, otherId: string) => {
			const { data, error: fetchError } = await event.locals.supabase
				.from('story')
				.select('colinked_stories')
				.eq('id', storyId)
				.single();

			if (fetchError || !data) {
				return { success: false, message: fetchError?.message || `Story ${storyId} not found` };
			}

			const current: number[] = data.colinked_stories ?? [];
			const otherIdInt = parseInt(otherId, 10);

			const updated = current.includes(otherIdInt) ? current : [...current, otherIdInt];

			const { error: updateError } = await event.locals.supabase
				.from('story')
				.update({ colinked_stories: updated })
				.eq('id', storyId);

			if (updateError) {
				return { success: false, message: updateError.message };
			}

			return { success: true };
		};

		const updateRequested = await updateColinkedStories(requestedStoryId, requesterStoryId);
		if (!updateRequested.success) return updateRequested;

		const updateRequester = await updateColinkedStories(requesterStoryId, requestedStoryId);
		if (!updateRequester.success) return updateRequester;

		const { error: deleteError } = await event.locals.supabase
			.from('notifications')
			.delete()
			.eq('type', 'colinking_pending')
			.eq('data->>requested_story_id', requestedStoryId)
			.eq('data->>requester_story_id', requesterStoryId);

		if (deleteError) {
			console.error('Failed to delete notification:', deleteError.message);
		}

		return { success: true };
	}
};

