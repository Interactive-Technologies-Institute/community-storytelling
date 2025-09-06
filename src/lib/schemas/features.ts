import { z } from 'zod';

export const updateFeaturesSchema = z.object({
	howtos: z.boolean(),
	events: z.boolean(),
	map: z.boolean(),
	academy: z.boolean(),
	stories: z.boolean(),
	members: z.boolean(),
});

export type UpdateFeaturesSchema = typeof updateFeaturesSchema;
