<script lang="ts">
	import ModerationBanner from '@/components/moderation-banner.svelte';
	import PageHeader from '@/components/page-header.svelte';
	import { Button } from '@/components/ui/button';
	import { Eye, LayoutPanelTop, Tag, Network, Trash, Wand } from 'lucide-svelte';
	import Pending from './_components/pending.svelte';
	import StoryDeleteDialog from './_components/story-delete-dialog.svelte';
	import StoryUnpublishDialog from './_components/story-unpublish-dialog.svelte';
	import Story from './_components/story.svelte';
	import StoryLikeButton from './_components/story-like-button.svelte';
	import * as Avatar from '../../../lib/components/ui/avatar';
	import { firstAndLastInitials } from '../../../lib/utils';

	export let data;

	let openDeleteDialog = false;
	let openUnpublishDialog = false;
</script>

<PageHeader
	title={data.story.storyteller}
	subtitle={data.story.role === 'interview' ? 'Interview' : 'Monologue'}
/>
	<div class="container mx-auto space-y-10 pb-10">
	{#if data.moderation[0].status !== 'approved'}
		<ModerationBanner moderation={data.moderation} />
	{:else}
		<div class="flex justify-center items-center gap-4 mb-6 mt-0">
			<span class="text-xl font-semibold">Autor:</span>
			<a href={`/users/${data.profile.id}`} class="flex items-center gap-2 hover:underline">
				<Avatar.Root class="h-12 w-12">
					<Avatar.Image src={data.profile.avatarUrl} alt={data.profile.display_name} />
					<Avatar.Fallback>{firstAndLastInitials(data.profile.display_name)}</Avatar.Fallback>
				</Avatar.Root>
				<span class="text-base text-foreground">{data.profile.display_name}</span>
			</a>
		</div>
		<div>
		{#if data.story.coauthors && data.story.coauthors.length > 0}
		<div class="flex flex-col items-center gap-4 mb-6">
			<span class="text-xl font-semibold">Co-autores:</span>
				<div class="flex flex-wrap justify-center gap-4">
					{#each data.story.coauthors as coauthorId}
						{#if data.coauthors?.[coauthorId]}
							<a href={`/users/${coauthorId}`} class="flex items-center gap-2 hover:underline">
								<Avatar.Root class="h-10 w-10">
									<Avatar.Image
										src={data.coauthors[coauthorId].avatarUrl}
										alt={data.coauthors[coauthorId].display_name}
									/>
									<Avatar.Fallback>
										{firstAndLastInitials(data.coauthors[coauthorId].display_name)}
									</Avatar.Fallback>
								</Avatar.Root>
								<span class="text-base text-foreground">
									{data.coauthors[coauthorId].display_name}
								</span>
							</a>
						{/if}
					{/each}
				</div>
			</div>
		{/if}
		</div>
		<div class="flex justify-center my-6">
			<StoryLikeButton count={data.likeCount} data={data.toggleLikeForm} />
		</div>
	{/if}
	<div class="mb-10 flex flex-col items-center gap-y-4">
		<div class="flex flex-row gap-x-2">
			{#each data.story.tags as tag}
				<Button variant="secondary" size="sm" href="/user/0">
					<Tag class="mr-2 h-4 w-4" />
					{tag}
				</Button>
			{/each}
		</div>
		{#if data.moderation[0].status == 'approved'}
			<Story data={data.story} />
		{/if}

		{#if data.permission}
			<div class="mb-12">
				<Pending data={data.story} />
			</div>
		{/if}

		{#if data.moderation[0].status === 'approved'}
			{#if data.story.colinked_stories && data.story.colinked_stories.length > 0}
				<div class="flex flex-col items-center gap-4 mb-10">
					<h1 class="text-4xl font-bold text-center">Histórias Ligadas</h1>

					<div class="flex flex-wrap justify-center gap-6 mt-4">
						{#each data.story.colinked_stories as storyId}
							{#if data.colinkedStories[storyId]}
								<a
									href={`/story/${storyId}`}
									class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
								>
								{data.colinkedStories[storyId].title}
								</a>
							{/if}
						{/each}
					</div>
				</div>
			{/if}
		{/if}
	</div>

	{#if data.permission}
		<div
			class="sticky bottom-0 flex w-full flex-col items-center justify-center gap-y-4 border-t bg-background/95 py-4 backdrop-blur supports-[backdrop-filter]:bg-background/60 sm:flex-row sm:gap-x-10 sm:py-8"
		>
			{#if data.story.transcription}
				<Button href="/story/{data.story.id}/transcription" class="w-full sm:w-auto">
					<Eye class="mr-2 h-4 w-4" />
					Abrir Transcrição
				</Button>
				{:else}
				<Button href="/story/{data.story.id}/edit-transcription" class="w-full sm:w-auto">
					<Wand class="mr-2 h-4 w-4" />
					Gerar Transcrição
				</Button>
			{/if}
			{#if data.story.user_id !== data.user?.id && data.moderation[0].status === 'approved'}
				<Button href="/story/{data.story.id}/colinking" class="w-full sm:w-auto">
					<Network class="mr-2 h-4 w-4" />
					Colinking
				</Button>
			{/if}
			{#if data.moderation[0].status === 'pending'}
				<Button href="/story/{data.story.id}/preview" class="w-full sm:w-auto">
					<LayoutPanelTop class="mr-2 h-4 w-4" />
					Pré-visualizar história
				</Button>
			{/if}
			{#if (data.story.user_id === data.user?.id || data.user?.role == 'moderator' || data.user?.role == 'admin') && data.moderation[0].status === 'approved'}
				<Button
					variant="destructive"
					on:click={() => (openUnpublishDialog = true)}
					class="w-full sm:w-auto"
				>
					<Trash class="mr-2 h-4 w-4" />
					Remover Publicação
				</Button>
			{/if}
			{#if data.story.user_id === data.user?.id || data.user?.role == 'moderator' || data.user?.role == 'admin'}
				<Button
					variant="destructive"
					on:click={() => (openDeleteDialog = true)}
					class="w-full sm:w-auto"
				>
					<Trash class="mr-2 h-4 w-4" />
					Excluir
				</Button>
			{/if}
		</div>
	{/if}


</div>

<StoryDeleteDialog storyId={data.story.id} data={data.deleteForm} bind:open={openDeleteDialog} />
<StoryUnpublishDialog
	storyId={data.story.id}
	data={data.unpublishForm}
	bind:open={openUnpublishDialog}
/>