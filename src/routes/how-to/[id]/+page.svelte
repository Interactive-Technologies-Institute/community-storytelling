<script lang="ts">
	import InteractableImage from '@/components/interactable-image.svelte';
	import ModerationBanner from '@/components/moderation-banner.svelte';
	import PageHeader from '@/components/page-header.svelte';
	import { Button } from '@/components/ui/button';
	import Card from '@/components/ui/card/card.svelte';
	import dayjs from 'dayjs';
	import { ChartNoAxesColumn, Clock, Footprints, Pen, Tag, Trash } from 'lucide-svelte';
	import { MetaTags } from 'svelte-meta-tags';
	import HowToDeleteDialog from './_components/how-to-delete-dialog.svelte';
	import UsefulButton from './_components/useful-button.svelte';

	export let data;

	let openDeleteDialog = false;
</script>

<MetaTags
	title={data.howTo.title}
	description={data.howTo.description}
	openGraph={{
		title: data.howTo.title,
		description: data.howTo.description,
		images: [{ url: data.howTo.image }],
	}}
	twitter={{
		cardType: 'summary_large_image',
		title: data.howTo.title,
		description: data.howTo.description,
		image: data.howTo.image,
	}}
/>

<PageHeader title={data.howTo.title} subtitle={data.howTo.description} />
<div class="container mx-auto space-y-10 pb-10">
	{#if data.moderation[0].status !== 'approved'}
		<ModerationBanner moderation={data.moderation} />
	{/if}
	<div class="flex flex-col items-center gap-y-4">
		<div class="flex flex-row items-center justify-center gap-x-4">
			<div class="flex flex-row items-center gap-x-2">
				<Footprints class="text-muted-foreground" />
				{data.howTo.steps.length}
			</div>
			<div class="flex flex-row items-center gap-x-2">
				<Clock class="text-muted-foreground" />
				{data.howTo.duration}
			</div>
			<div class="flex flex-row items-center gap-x-2">
				<ChartNoAxesColumn class="text-muted-foreground" />
				{data.howTo.difficulty}
			</div>
		</div>
		<UsefulButton count={data.usefulCount} data={data.toggleUsefulForm} />
	</div>
	<div class="mx-auto flex max-w-2xl flex-col gap-y-4">
		<InteractableImage
			src={data.howTo.image}
			alt="How To Cover"
			class="aspect-[3/2] h-auto w-full rounded-md object-cover"
		/>
		<p>{data.howTo.description}</p>
		<div class=" flex flex-wrap gap-2">
			{#each data.howTo.tags as tag}
				<Button variant="secondary" size="sm" href="/how-to?tags={tag}">
					<Tag class="mr-2 h-4 w-4" />
					{tag}
				</Button>
			{/each}
		</div>
	</div>
	<div class="flex flex-col gap-y-10">
		{#each data.howTo.steps as step, i}
			<div class="flex flex-row gap-x-6">
				<Card class="hidden h-fit w-32 items-center justify-center py-4 md:flex">
					<span class="text-2xl font-medium">{i + 1}</span>
				</Card>
				<Card class="grid w-full grid-cols-1 overflow-hidden lg:grid-cols-2">
					<div class="px-6 py-5">
						<h2 class="mb-2 text-2xl font-medium">
							<span class="md:hidden">{i + 1}. </span>
							{step.title}
						</h2>
						<p>{step.description}</p>
					</div>
					<InteractableImage
						src={step.image}
						alt="Step {i + 1}"
						class="aspect-[3/2] h-auto w-full object-cover"
					/>
				</Card>
			</div>
		{/each}
	</div>
	<div class="flex flex-col items-center">
		<p class="text-xs text-muted-foreground">
			Published {dayjs(data.howTo.inserted_at).fromNow()}
			{#if data.howTo.inserted_at !== data.howTo.updated_at}
				• Updated {dayjs(data.howTo.updated_at).fromNow()}
			{/if}
		</p>
		<Button variant="link" size="sm" href="/users/{data.howTo.author.id}">
			by
			{data.howTo.author.display_name}
		</Button>
	</div>
	{#if data.howTo.user_id === data.user?.id}
		<div
			class="sticky bottom-0 flex w-full flex-row items-center justify-center gap-x-10 border-t bg-background/95 py-8 backdrop-blur supports-[backdrop-filter]:bg-background/60"
		>
			<Button variant="outline" href="/how-to/{data.howTo.id}/edit">
				<Pen class="mr-2 h-4 w-4" />
				Edit
			</Button>
			<Button variant="destructive" on:click={() => (openDeleteDialog = true)}>
				<Trash class="mr-2 h-4 w-4" />
				Delete
			</Button>
		</div>
	{/if}
</div>

<HowToDeleteDialog howToId={data.howTo.id} data={data.deleteForm} bind:open={openDeleteDialog} />
