import type { Story } from "@/types/types";
import type { MapPin } from "@/types/types";
import { error } from "@sveltejs/kit";
import { setFlash } from "sveltekit-flash-message/server";

export const load = async (event) => {
	async function getPins(): Promise<MapPin[]> {
		const { data: approvedModerations, error: moderationError } = await event.locals.supabase
			.from('map_pins_moderation')
			.select('map_pin_id')
			.eq('status', 'approved');
		
		if (moderationError) {
			const errorMessage = 'Error fetching map pins, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}
		
		const approvedIds = approvedModerations?.map((m) => m.map_pin_id);
		
		const { data: mapPins, error: mapPinsError } = await event.locals.supabase
			.from('map_pins_view')
			.select('*, moderation:map_pins_moderation(status, inserted_at, comment)')
			.in('id', approvedIds)
			.order('updated_at', { ascending: false });
		
		if (mapPinsError) {
			const errorMessage = 'Error fetching map pins, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}
		
		return mapPins;
	}

	async function getStories(): Promise<Story[]> {
		const { data: stories, error } = await event.locals.supabase
			.from('story_view')
			.select('id, title, role')
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
