<script lang="ts">
	import { page } from '$app/stores';
	import type { Doc } from '@/types/types';
	import { cn } from '@/utils';

	export let groupSlug: string;
	export let doc: Doc;
	$: path = `/academy/${groupSlug}/${doc.slug}`;
	$: isSelected = path === $page.url.pathname;
</script>

<li>
	<a
		href={path}
		class={cn(
			'transition-colors hover:text-foreground/80',
			isSelected ? 'text-foreground' : 'text-foreground/60'
		)}>{doc.title}</a
	>
</li>
