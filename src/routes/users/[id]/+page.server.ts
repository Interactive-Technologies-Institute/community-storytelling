import type { UserProfile } from '@/types/types';
import { handleSignInRedirect } from '@/utils';
import { error, redirect } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';

export const load = async (event) => {
	const { session, user } = await event.locals.safeGetSession();

	let id = event.params.id;
	if (id === 'me') {
		if (!session || !user) {
			return redirect(302, handleSignInRedirect(event));
		}
		id = user.id;
	}

	async function getUserProfile(): Promise<UserProfile> {
		const { data: userProfile, error: userProfileError } = await event.locals.supabase
			.from('profiles_view')
			.select('*')
			.eq('id', id)
			.single();

		if (userProfileError) {
			const errorMessage = 'Error fetching  profile, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		if (userProfile.avatar) {
			userProfile.avatar = event.locals.supabase.storage
				.from('avatars')
				.getPublicUrl(userProfile.avatar).data.publicUrl;
		}

		return userProfile;
	}

	async function getHowTos(): Promise<{ id: number; label: string }[]> {
		const { data: howTos, error: howTosError } = await event.locals.supabase
			.from('howtos_view')
			.select('id, label:title')
			.order('moderation_status', { ascending: true })
			.order('inserted_at', { ascending: false })
			.eq('user_id', id);

		if (howTosError) {
			const errorMessage = 'Error fetching how tos, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return howTos;
	}

	async function getEvents(): Promise<{ id: number; label: string }[]> {
		const { data: events, error: eventsError } = await event.locals.supabase
			.from('events_view')
			.select('id, label:title')
			.order('moderation_status', { ascending: true })
			.order('inserted_at', { ascending: false })
			.eq('user_id', id);

		if (eventsError) {
			const errorMessage = 'Error fetching events, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return events;
	}

	async function getMapPin(): Promise<{ id: number } | null> {
		const { data: mapPin, error: mapPinError } = await event.locals.supabase
			.from('map_pins_view')
			.select('id')
			.eq('user_id', id)
			.maybeSingle();

		if (mapPinError) {
			const errorMessage = 'Error fetching map pin, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return mapPin;
	}

	return {
		userProfile: await getUserProfile(),
		howTos: await getHowTos(),
		events: await getEvents(),
		mapPin: await getMapPin(),
	};
};
