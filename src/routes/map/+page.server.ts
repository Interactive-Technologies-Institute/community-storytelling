/* import { createMapPinSchema, deleteMapPinSchema } from '@/schemas/map-pin';
import type { ModerationInfo, UserProfileWithPin, UserType } from '@/types/types';
import { handleFormAction, numberQueryParam } from '@/utils';
import { error, fail, redirect } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';
import { superValidate } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';

export const load = async (event) => {
	const id = numberQueryParam().decode(event.url.searchParams.get('id'));
	let location: { lat: number; lng: number } | undefined;

	if (id) {
		location = await getLocationById(id);
	}
	if (location) {
		const lat = numberQueryParam().encode(location.lat);
		const lng = numberQueryParam().encode(location.lng);
		if (lat && lng) {
			const url = new URL(event.url);
			url.searchParams.delete('id');
			url.searchParams.set('lat', lat);
			url.searchParams.set('lng', lng);
			url.searchParams.set('zoom', '10');
			redirect(302, url.toString());
		}
	}

	const { session, user, profile } = await event.parent();

	let profileWithPin: UserProfileWithPin | undefined;
	if (session && user && profile) {
		const { data: pinData } = await event.locals.supabase
			.from('map_pins_view')
			.select('*')
			.eq('user_id', user.id)
			.single();
		profileWithPin = {
			...profile,
			pin: pinData,
		};
	}

	async function getUserTypes(): Promise<UserType[]> {
		const { data: userTypes, error: userTypesError } = await event.locals.supabase
			.from('user_types')
			.select('*');

		if (userTypesError) {
			const errorMessage = 'Error fetching user types, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return userTypes;
	}

	async function getMapPinModeration(id: number): Promise<ModerationInfo[]> {
		const { data: moderation, error: moderationError } = await event.locals.supabase
			.from('map_pins_moderation')
			.select('*')
			.eq('map_pin_id', id)
			.order('inserted_at', { ascending: false });

		if (moderationError) {
			const errorMessage = 'Error fetching moderation, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return moderation;
	}

	async function getUsersWithMapPins(): Promise<UserProfileWithPin[]> {
		const { data: mapPins, error: mapPinsError } = await event.locals.supabase
			.from('profiles_view')
			.select('*, pin:map_pins_view(*)');

		if (mapPinsError) {
			const errorMessage = 'Error fetching map pins, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return mapPins;
	}

	async function getLocationById(id: number): Promise<{ lat: number; lng: number }> {
		const { data: location, error: locationError } = await event.locals.supabase
			.from('map_pins_view')
			.select('*')
			.eq('id', id)
			.single();

		if (locationError) {
			const errorMessage = 'Error fetching location, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		return { lat: location.lat, lng: location.lng };
	}

	return {
		profile: profileWithPin,
		moderation: profileWithPin?.pin ? await getMapPinModeration(profileWithPin.pin.id) : undefined,
		userTypes: await getUserTypes(),
		users: await getUsersWithMapPins(),
		createForm: await superValidate(zod(createMapPinSchema), {
			id: 'create-map-pin',
		}),
		updateForm: await superValidate(
			{
				lng: profileWithPin?.pin?.lng ?? 0,
				lat: profileWithPin?.pin?.lat ?? 0,
			},
			zod(createMapPinSchema),
			{
				id: 'update-map-pin',
			}
		),
		deleteForm: await superValidate(zod(deleteMapPinSchema), {
			id: 'delete-map-pin',
		}),
	};
};

export const actions = {
	create: async (event) =>
		handleFormAction(event, createMapPinSchema, 'create-map-pin', async (event, userId, form) => {
			const { error } = await event.locals.supabase
				.from('map_pins')
				.insert({ ...form.data, user_id: userId });

			if (error) {
				setFlash({ type: 'error', message: error.message }, event.cookies);
				return fail(500, { message: error.message, form });
			}

			setFlash({ type: 'success', message: 'Your pin has been updated.' }, event.cookies);
			return { form };
		}),
	update: async (event) =>
		handleFormAction(event, createMapPinSchema, 'update-map-pin', async (event, userId, form) => {
			const { error } = await event.locals.supabase
				.from('map_pins')
				.update(form.data)
				.eq('user_id', userId);

			if (error) {
				setFlash({ type: 'error', message: error.message }, event.cookies);
				return fail(500, { message: error.message, form });
			}

			setFlash({ type: 'success', message: 'Your pin has been updated.' }, event.cookies);
			return { form };
		}),
	delete: async (event) =>
		handleFormAction(event, deleteMapPinSchema, 'delete-map-pin', async (event, userId, form) => {
			const { error } = await event.locals.supabase
				.from('map_pins')
				.delete()
				.eq('id', form.data.id);

			if (error) {
				setFlash({ type: 'error', message: error.message }, event.cookies);
				return fail(500, { message: error.message, form });
			}

			setFlash({ type: 'success', message: 'Your pin has been deleted.' }, event.cookies);
			return { form };
		}),
};
*/ 

export const load = async (event) => {
  // Query your Supabase table, e.g. 'story' or 'locations'
  const { data: pins, error } = await event.locals.supabase
    .from('map_pins') // or your table name
    .select('lat, lng, year, story_id')
    .not('lat', 'is', null)
    .not('lng', 'is', null);

  if (error) {
    console.error('Error fetching pins:', error);
    return { pins: [] };
  }

  return { pins };
};
