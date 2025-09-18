import { z } from 'zod';

export const editStorySchema = z.object({
    storyteller: z.string().min(5, { message: 'Name is required' }).max(100),
    tags: z.array(z.string()).min(1, { message: 'At least one tag is required' }),
    lat: z.number().min(-90).max(90).optional(),
    lng: z.number().min(-180).max(180).optional(),
    pinColor: z.string().optional(),
    coauthors: z.array(z.string().uuid()).optional(),
    extra: z.object({ users: z.array(z.object({ id: z.string(), display_name: z.string() })) }).optional(),
    transcription: z.string().nullable(),
});

export type EditStorySchema = typeof editStorySchema;
