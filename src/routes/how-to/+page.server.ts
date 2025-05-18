import type { HowTo } from '@/types/types';
import { arrayQueryParam, stringQueryParam } from '@/utils';
import { error } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';

export const load = async (event) => {
	const search = stringQueryParam().decode(event.url.searchParams.get('s'));
	const tags = arrayQueryParam().decode(event.url.searchParams.get('tags'));

	async function getHowTos(): Promise<HowTo[]> {
		let query = event.locals.supabase
			.from('howtos_view')
			.select('*')
			.order('moderation_status', { ascending: true })
			.order('inserted_at', { ascending: false });

		if (search) {
			query = query.textSearch('fts', search, { config: 'simple', type: 'websearch' });
		}

		if (tags && tags.length) {
			query = query.overlaps('tags', tags);
		}

		const { data: howTos, error: howTosError } = await query;

		if (howTosError) {
			const errorMessage = 'Error fetching how tos, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}
		return howTos;
	}

	async function getTags(): Promise<Map<string, number>> {
		const { data: tags, error: tagsError } = await event.locals.supabase
			.from('howtos_tags')
			.select();

		if (tagsError) {
			const errorMessage = 'Error fetching tags, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		const tagMap = new Map<string, number>();
		if (tags) {
			tags.forEach((tag) => {
				const { count, tag: tagName } = tag;
				if (count !== null && tagName !== null) {
					tagMap.set(tagName, count);
				}
			});
		}

		return tagMap;
	}

	return {
		howTos: await getHowTos(),
		tags: await getTags(),
	};
};
