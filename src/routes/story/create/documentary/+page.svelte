<script lang="ts">
	import StoryForm from './_components/story-form.svelte';
	import PageHeader from '@/components/page-header.svelte';

	export let data;
</script>

<svelte:head>
	<title>Criar história</title>
	<meta name="description" content="Interview Someone! (or get someone to interview you!)" />
</svelte:head>

<PageHeader title={'Entrevista'} subtitle="" />
<div class="container mx-auto space-y-10 pb-10">
	<StoryForm data={data.createForm} />
</div>
