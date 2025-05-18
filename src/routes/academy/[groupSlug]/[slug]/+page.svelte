<script lang="ts">
	import { page } from '$app/stores';
	import { MetaTags } from 'svelte-meta-tags';
	import DocBreadcrumbs from '../../_components/doc-breadcrumbs.svelte';

	export let data;
</script>

<MetaTags title={data.meta.title} />

<DocBreadcrumbs
	docs={data.docs}
	grougSlug={$page.params.groupSlug}
	slug={$page.params.slug}
	title={data.meta.title}
/>
<div class="prose mt-6 max-w-none dark:prose-invert">
	<svelte:component this={data.content} />
</div>
