import { updatePasswordSchema } from '@/schemas/password';
import { updateUserProfileSchema } from '@/schemas/user-profile';
import { handleFormAction, handleSignInRedirect } from '@/utils';
import type { StorageError } from '@supabase/storage-js';
import { error, redirect } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';
import { fail, superValidate, withFiles } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';

export const load = async (event) => {
	const { session, user } = await event.locals.safeGetSession();
	if (!session) {
		return redirect(302, handleSignInRedirect(event));
	}

	let id = event.params.id;
	if (id === 'me') {
		if (!session || !user) {
			return redirect(302, handleSignInRedirect(event));
		}
		id = user.id;
	}

	async function getUserProfile(id: string) {
		const { data: userProfile, error: userProfileError } = await event.locals.supabase
			.from('profiles_view')
			.select('*')
			.eq('id', id)
			.single();

		if (userProfileError) {
			const errorMessage = 'Error fetching user profile, please try again later.';
			setFlash({ type: 'error', message: errorMessage }, event.cookies);
			return error(500, errorMessage);
		}

		let avatarUrl = '';
		if (userProfile.avatar) {
			avatarUrl = event.locals.supabase.storage.from('users').getPublicUrl(userProfile.avatar).data.publicUrl ?? '';
		}

		return { ...userProfile, avatar: null, avatarUrl, avatarPath: userProfile.avatar ?? ''};
	}

	const userProfileData = await getUserProfile(id);

	return {
		updateProfile: await superValidate(userProfileData, zod(updateUserProfileSchema), {
			id: 'update-profile',
		}),
		updatePassword: await superValidate(zod(updatePasswordSchema), {
			id: 'update-password',
		}),
	};
};

export const actions = {
	updateProfile: async (event) =>
		handleFormAction(
			event,
			updateUserProfileSchema,
			'update-profile',
			async (event, userId, form) => {
				async function uploadAvatar(
					avatar: File
				): Promise<{ path: string; error: StorageError | null }> {
					const fileExt = avatar.name.split('.').pop();
					const filePath = `${userId}/avatar.${fileExt}?updated=${Date.now()}`;

					const { data: avatarFileData, error: avatarFileError } =
						await event.locals.supabase.storage.from('users').upload(filePath, avatar, {
							upsert: true,
						});

					if (avatarFileError) {
						setFlash({ type: 'error', message: avatarFileError.message }, event.cookies);
						return { path: '', error: avatarFileError };
					}

					return { path: avatarFileData.path, error: null };
				}

				let avatarPath: string | undefined = undefined;

				if (form.data.avatarReset === true && form.data.avatarPath) {
					const avatarFileName = form.data.avatarPath.split('?')[0];

					console.log(avatarFileName);

					const { error: deleteError } = await event.locals.supabase.storage
						.from('users')
						.remove([avatarFileName]);

					if (deleteError) {
						setFlash({ type: 'error', message: deleteError.message }, event.cookies);
						return fail(500, withFiles({ message: deleteError.message, form }));
					}

					avatarPath = undefined;
					form.data.avatarReset = false;
				}

				else if (form.data.avatar) {
					const { path, error } = await uploadAvatar(form.data.avatar);
					if (error) {
						return fail(500, withFiles({ message: error.message, form }));
					}
					avatarPath = path;
				}

				else if (form.data.avatarPath) {
						avatarPath = form.data.avatarPath;
				}

				const updatedProfile: Record<string, any> = {
					display_name: form.data.display_name,
					description: form.data.description,
				};

				if (avatarPath !== undefined) {
					updatedProfile.avatar = avatarPath;
				}

				else {
					updatedProfile.avatar = '';
				}

				const { error: profileError } = await event.locals.supabase
					.from('profiles')
					.update(updatedProfile)
					.eq('id', userId);

				if (profileError) {
					setFlash({ type: 'error', message: profileError.message }, event.cookies);
					return fail(500, withFiles({ message: profileError.message, form }));
				}

				setFlash({ type: 'success', message: 'Profile updated successfully' }, event.cookies);
				withFiles({ form });

				throw redirect(303, '/users/me')
			}
		),
	updatePassword: async (event) =>
		handleFormAction(
			event,
			updatePasswordSchema,
			'update-password',
			async (event, userId, form) => {
				const { data: verifyData } = await event.locals.supabase.rpc('verify_user_password', {
					password: form.data.currentPassword,
				});

				if (!verifyData) {
					setFlash({ type: 'error', message: 'Current password is incorrect' }, event.cookies);
					return fail(500, { message: 'Current password is incorrect', form });
				}

				const { error: updateError } = await event.locals.supabase.auth.updateUser({
					password: form.data.newPassword,
				});

				if (updateError) {
					setFlash({ type: 'error', message: updateError.message }, event.cookies);
					return fail(500, { message: updateError.message, form });
				}

				setFlash({ type: 'success', message: 'Password updated successfully' }, event.cookies);
				return { form };
			}
		),
};
