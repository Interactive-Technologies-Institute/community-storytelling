import { z } from 'zod';

export const createHowToSchema = z
	.object({
		title: z
			.string()
			.min(5, { message: 'Title must be at least 5 characters' })
			.max(100, { message: 'Title must be less than 100 characters' }),
		description: z
			.string()
			.min(5, { message: 'Description must be at least 5 characters' })
			.max(500, { message: 'Description must be less than 500 characters' }),
		imageUrl: z.string().nullish(),
		image: z.instanceof(File).nullish(),
		tags: z
			.array(z.string())
			.refine((tags) => tags.length <= 5, {
				message: 'Must be less than 5 tags',
			})
			.refine((tags) => {
				return new Set(tags).size === tags.length;
			}, 'Tags must be unique')
			.refine((tags) => {
				return tags.every((tag) => tag.length >= 3 && tag.length <= 20);
			}, 'Tags must be between 3 and 20 characters'),
		difficulty: z.enum(['easy', 'medium', 'hard']),
		duration: z.enum(['short', 'medium', 'long']),
		steps: z
			.array(
				z
					.object({
						title: z
							.string()
							.min(5, { message: 'Title must be at least 5 characters' })
							.max(100, { message: 'Title must be less than 100 characters' }),
						description: z
							.string()
							.min(5, { message: 'Description must be at least 5 characters' })
							.max(500, { message: 'Description must be less than 500 characters' }),
						imageUrl: z.string().nullish(),
						image: z.instanceof(File).nullish(),
					})
					.refine((data) => data.image || data.imageUrl, {
						message: 'Image is required',
						path: ['image'],
					})
			)
			.min(3, { message: 'At least 3 steps are required' })
			.default([
				{
					title: '',
					description: '',
				},
				{
					title: '',
					description: '',
				},
				{
					title: '',
					description: '',
				},
			]),
	})
	.refine((data) => data.image || data.imageUrl, {
		message: 'Image is required',
		path: ['image'],
	});

export type CreateHowToSchema = typeof createHowToSchema;

export const deleteHowToSchema = z.object({
	id: z.number(),
});

export type DeleteHowToSchema = typeof deleteHowToSchema;

export const toggleHowToUsefulSchema = z.object({
	value: z.boolean(),
});

export type ToggleHowToUsefulSchema = typeof toggleHowToUsefulSchema;
