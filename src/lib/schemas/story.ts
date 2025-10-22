import { z } from 'zod';

export const createStorySchema = z.object({
	storyteller: z.string().min(2, { message: 'O nome deve ter pelo menos 2 letras' }).max(100, 'O nome deve ter no máximo 100 letras'),
	recording_link: z.string().min(5, { message: 'Cloudinary Link is required' }).max(500).optional(),
	tags: z.array(z.string()).min(1, { message: 'At least one tag is required' }),
	year: z.string().optional().refine((val) => { if (!val) return true; const num = Number(val); return !isNaN(num) && num >= 1950 && num <= 2030; }, { message: 'Se preenchido, o período deve estar entre 1950 e 2030', }),
	type: z.enum(['monologue', 'interview']),
	image: z.array(z.string()).min(2, { message: 'At least two images are required' }),
	lat: z.number().min(-90).max(90).optional(),
	lng: z.number().min(-180).max(180).optional(),
	pinColor: z.string().optional(),
	coauthors: z.array(z.string().uuid()).optional(),
	extra: z.object({ users: z.array(z.object({ id: z.string(), display_name: z.string() })) }).optional(),
});

export type CreateStorySchema = typeof createStorySchema;

export const approveStorySchema = z.object({
	id: z.number(),
	userId: z.string(),
});

export type ApproveStorySchema = typeof approveStorySchema;

export const deleteStorySchema = z.object({
	id: z.number(),
	userId: z.string(),
});

export type DeleteStorySchema = typeof deleteStorySchema;

export const unpublishStorySchema = z.object({
	id: z.number(),
	comment: z.string().min(1, "O comentário é obrigatório"),
	userId: z.string(),
});

export type UnpublishStorySchema = typeof unpublishStorySchema;

export const toggleStoryLikeSchema = z.object({
	value: z.boolean(),
});

export type toggleStoryLikeSchema = typeof toggleStoryLikeSchema;
