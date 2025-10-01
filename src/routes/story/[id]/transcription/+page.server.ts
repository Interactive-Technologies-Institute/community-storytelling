import type { ModerationInfo, Story } from '@/types/types.js';
import { error } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';

export const load = async (event) => {
	const { user } = await event.parent();

	async function getStoryInfo(id: string): Promise<Story> {
		const { data: storyInfo, error: storyError } = await event.locals.supabase
			.from('story_view')
			.select('id, user_id, recording_link, transcription')
			.eq('id', id)
			.single();

		if (storyError) {
			const errorMessage = `Error fetching video link, please try again later.`;
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return storyInfo as Story;
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

	return {
		story: await getStoryInfo(event.params.id),
		userId: user?.id,
		storyModeration: await getStoryModeration(event.params.id),
	};
};
