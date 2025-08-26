import { sendConnectionNotificationSchema } from '@/schemas/colinking';
import type { Story } from '@/types/types';
import { handleFormAction } from '@/utils';
import { error, fail, redirect } from '@sveltejs/kit';
import { setFlash } from 'sveltekit-flash-message/server';

export const load = async (event) => {
    const { user } = await event.parent();

    async function getStory(id: string): Promise<Story> {
        const { data: story, error: storyError } = await event.locals.supabase
            .from('story_view')
            .select('*')
            .eq('id', id)
            .single();

        if (storyError) {
            const errorMessage = `Error fetching story ${id}, please try again later.`;
            setFlash({ type: 'error', message: errorMessage }, event.cookies);
            return error(500, errorMessage);
        }

        return story as Story;
    }

    async function getMyStories(): Promise<Story[]> {
        if(user){
            const { data: allStories, error: allStoriesError } = await event.locals.supabase
                .from('story_view')
                .select('id, title')
                .eq('user_id', user.id);

            if (allStoriesError) {
                const errorMessage = 'Erro ao buscar suas histórias. Tente novamente mais tarde.';
                setFlash({ type: 'error', message: errorMessage }, event.cookies);
                throw error(500, errorMessage);
            }

            return allStories as Story[];
        }

        return [];
    }

    return {
        story: await getStory(event.params.id),
        myStories: await getMyStories()
    };
};

export const actions = {
    sendNotification: async (event) =>
        handleFormAction(
            event,
            sendConnectionNotificationSchema,
            'send-notification',
            async (event, userId, form) => {
                const { requested_story_id, requester_story_id } = form.data;

                const { data: storyData, error: storyError } = await event.locals.supabase
                    .from('story_view')
                    .select('user_id')
                    .eq('id', requested_story_id)
                    .single();

                if (storyError) {
                    setFlash({ type: 'error', message: storyError.message }, event.cookies);
                    return fail(500, { message: storyError.message, form });
                }

                const recipient_user_id = storyData.user_id;

                if (!recipient_user_id) {
                    return fail(400, { message: 'Recipient user ID not found', form });
                }

                const { error: notifError } = await event.locals.supabase
                    .from('notifications')
                    .insert([
                        {
                            user_id: recipient_user_id,
                            type: 'colinking_pending',
                            data: {
                                requested_story_id: String(requested_story_id),
                                requester_story_id: String(requester_story_id)
                            },
                        }
                    ]);

                if (notifError) {
                    setFlash({ type: 'error', message: notifError.message }, event.cookies);
                    return fail(500, { message: notifError.message, form });
                }

                setFlash({ type: 'success', message: 'Pedido de conexão enviado!' }, event.cookies);
                return redirect(303, `/story/${requested_story_id}`);
            }
        )
};
