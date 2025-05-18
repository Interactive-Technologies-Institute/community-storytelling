<script lang="ts">
	import PageHeader from '@/components/page-header.svelte';
	import DocGroupTab from './_components/doc-group-tab.svelte';

	export let data;
</script>

<PageHeader title="Academy" subtitle="Explore our knowledge base" />
<div class="container mx-auto mb-20 flex flex-row">
	<div class="hidden w-44 flex-col gap-y-3 md:flex">
		{#each data.docs as docGroup, index}
			<DocGroupTab {index} {docGroup}></DocGroupTab>
		{/each}
	</div>
	<div class="flex-1"><slot /></div>
</div>
