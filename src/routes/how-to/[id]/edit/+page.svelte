<script lang="ts">
	import PageHeader from '@/components/page-header.svelte';
	import { MetaTags } from 'svelte-meta-tags';
	import HowToForm from '../../_components/how-to-form.svelte';
	export let data;
</script>

<MetaTags title="Edit How To" description="Edit this how to" />

<PageHeader title="Edit How To" subtitle="Edit this how to" />
<div class="container mx-auto mb-20">
	<HowToForm data={data.updateForm} />
</div>
