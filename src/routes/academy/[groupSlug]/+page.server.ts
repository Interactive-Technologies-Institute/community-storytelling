import { error, redirect } from '@sveltejs/kit';

export async function load({ parent, params }) {
	const { docs } = await parent();

	const groupSlug = params.groupSlug;

	const groupDocs = docs.find((group) => group.slug === groupSlug);

	if (groupDocs?.docs.length === 0) {
		error(404, 'Not found');
	} else {
		redirect(307, '/academy/' + groupSlug + '/' + groupDocs?.docs[0].slug + '/');
	}
}
