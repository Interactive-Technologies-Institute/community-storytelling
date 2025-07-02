import type { Story } from "@/types/types";
import type { MapPin } from "@/types/types";

export const load = async (event) => {
	async function getPins(): Promise<MapPin[]> {
		const { data: pins, error } = await event.locals.supabase
		.from('map_pins_view')
		.select('lat, lng, year, story_id')
		.not('lat', 'is', null)
		.not('lng', 'is', null);

		if (error) {
			console.error('Error fetching pins:', error);
		}

		return pins as MapPin[];
	}

	async function getStories(): Promise<Story[]> {
		const { data: stories, error } = await event.locals.supabase
			.from('story_view')
			.select('id, title')
		if (error) {
			console.error('Error fetching stories:', error);
		}

		return stories as Story[];
   }

  return { 
	pins: await getPins(),
	stories: await getStories(),
	};
};
