import { z } from 'zod';

export const updateUserProfileSchema = z.object({
	display_name: z.string().min(1, { message: 'Display name is required' }),
	description: z
		.string()
		.max(250, { message: 'Description must be less than 250 characters' })
		.nullish(),
	avatar: z.instanceof(File).nullish(),
	avatarUrl: z.string().nullish(),
	avatarPath: z.string().optional(),
});

export type UpdateUserProfileSchema = typeof updateUserProfileSchema;
