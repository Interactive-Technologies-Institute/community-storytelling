import type { UserProfile } from '$lib/types/types';
import { error } from '@sveltejs/kit';

export const load = async (event) => {
    const { data: users, error: usersError } = await event.locals.supabase
		.from('profiles_view')
		.select('*');

	if (usersError) {
		throw error(500, 'Error fetching users');
	}

	const normalizedUsers: (UserProfile & { avatarUrl: string })[] = await Promise.all(
		(users ?? []).map(async (profile) => {
			let avatarUrl = '';
			if (profile.avatar) {
				avatarUrl =
					event.locals.supabase.storage
						.from('users')
						.getPublicUrl(profile.avatar)
						.data.publicUrl ?? '';
			}
			return { ...profile, avatarUrl };
		})
	);

	return { users: normalizedUsers };
};
