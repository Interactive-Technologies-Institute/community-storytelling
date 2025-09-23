import { createEventSchema } from '@/schemas/event';
import { handleFormAction, handleSignInRedirect } from '@/utils';
import type { StorageError } from '@supabase/storage-js';
import { fail, redirect } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';
import { superValidate, withFiles } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';
import { v4 as uuidv4 } from 'uuid';

export const load = async (event) => {
	const { session } = await event.locals.safeGetSession();
	const { user } = await event.parent();

	if (!session) {
		return redirect(302, handleSignInRedirect(event));
	}

	if (user?.role == 'user'){
		return redirect(303, '/');
	}

	return {
		createForm: await superValidate(zod(createEventSchema), {
			id: 'create-event',
		}),
	};
};

export const actions = {
	default: async (event) =>
		handleFormAction(event, createEventSchema, 'create-event', async (event, userId, form) => {
			async function uploadImage(
				image: File
			): Promise<{ path: string; error: StorageError | null }> {
				const fileExt = image.name.split('.').pop();
				const filePath = `${uuidv4()}.${fileExt}`;

				const { data: imageFileData, error: imageFileError } = await event.locals.supabase.storage
					.from('events')
					.upload(filePath, image);

				if (imageFileError) {
					setFlash({ type: 'error', message: imageFileError.message }, event.cookies);
					return { path: '', error: imageFileError };
				}

				return { path: imageFileData.path, error: null };
			}

			let imagePath = '';
			if (form.data.image) {
				const { path, error } = await uploadImage(form.data.image);
				if (error) {
					return fail(500, withFiles({ message: error.message, form }));
				}
				imagePath = path;
			} else if (form.data.imageUrl) {
				imagePath = form.data.imageUrl.split('/').pop() ?? '';
			}

			// eslint-disable-next-line @typescript-eslint/no-unused-vars
			const { imageUrl, ...data } = form.data;
			const { error: supabaseError } = await event.locals.supabase
				.from('events')
				.insert({ ...data, user_id: userId, image: imagePath });

			if (supabaseError) {
				setFlash({ type: 'error', message: supabaseError.message }, event.cookies);
				return fail(500, withFiles({ message: supabaseError.message, form }));
			}

			return redirect(303, '/events');
		}),
};
