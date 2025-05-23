import { handleSignInRedirect } from '@/utils';
import { redirect } from '@sveltejs/kit';

export const load = async (event) => {
    const { session } = await event.locals.safeGetSession();
    if (!session) {
        return redirect(302, handleSignInRedirect(event));
    }

    return;
};