import { z } from 'zod';

export const sendConnectionNotificationSchema = z.object({
    requested_story_id: z.number(),
    requester_story_id: z.number(),
    all_requester_stories: z.array(z.object({ id: z.string(), title: z.string() })).optional(),
});

export type sendConnectionNotificationSchema = typeof sendConnectionNotificationSchema;