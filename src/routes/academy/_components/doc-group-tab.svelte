<script lang="ts">
	import type { DocGroup } from '@/types/types';
	import DocTab from './doc-tab.svelte';

	export let index: number;
	export let docGroup: DocGroup;
</script>

<div>
	<h2 class="mb-2 text-2xl font-medium">{index + 1}. {docGroup.title}</h2>
	<ul class="flex flex-col gap-y-1">
		{#each docGroup.docs as doc}
			<DocTab groupSlug={docGroup.slug} {doc}></DocTab>
		{/each}
	</ul>
</div>
