import { z } from 'zod';

export const editStorySchema = z.object({
    storyteller: z.string().min(2, { message: 'O nome deve ter pelo menos 2 letras' }).max(100, 'O nome deve ter no máximo 100 letras'),
    tags: z.array(z.string()).min(1, { message: 'At least one tag is required' }),
    lat: z.number().min(-90).max(90).optional(),
    lng: z.number().min(-180).max(180).optional(),
    pinColor: z.string().optional(),
    coauthors: z.array(z.string().uuid()).optional(),
    year: z.string().optional().refine((val) => { if (!val) return true; const num = Number(val); return !isNaN(num) && num >= 1950 && num <= 2030; }, { message: 'Se preenchido, o período deve estar entre 1950 e 2030', }),
    extra: z.object({ users: z.array(z.object({ id: z.string(), display_name: z.string() })) }).optional(),
    transcription: z.string().nullable(),
});

export type EditStorySchema = typeof editStorySchema;
