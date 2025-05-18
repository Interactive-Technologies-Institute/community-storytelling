<script lang="ts">
	import PageHeader from '@/components/page-header.svelte';
	import { MetaTags } from 'svelte-meta-tags';
	import HowToForm from '../_components/how-to-form.svelte';
	export let data;
</script>

<MetaTags title="Create How To" description="Create a new how to and share it with the community" />

<PageHeader title="Create How To" subtitle="Create a new how to and share it with the community" />
<div class="container mx-auto mb-20">
	<HowToForm data={data.createForm} />
</div>
