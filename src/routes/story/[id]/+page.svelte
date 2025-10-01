<script lang="ts">
	import ModerationBanner from '@/components/moderation-banner.svelte';
	import PageHeader from '@/components/page-header.svelte';
	import { Button } from '@/components/ui/button';
	import { Eye, LayoutPanelTop, Tag, Network, Trash, Wand, Pencil, Check, MessageCircleCode } from 'lucide-svelte';
	import Pending from './_components/pending.svelte';
	import StoryApproveDialog from './_components/story-approve-dialog.svelte';
	import StoryDeleteDialog from './_components/story-delete-dialog.svelte';
	import StoryUnpublishDialog from './_components/story-unpublish-dialog.svelte';
	import Story from './_components/story.svelte';
	import StoryLikeButton from './_components/story-like-button.svelte';
	import * as Avatar from '../../../lib/components/ui/avatar';
	import { firstAndLastInitials } from '../../../lib/utils';
	import { goto } from '$app/navigation';

	export let data;

	let openApproveDialog = false;
	let openDeleteDialog = false;
	let openUnpublishDialog = false;

	const isOwner = data.story.user_id === data.user?.id;
	const isModerator = data.user?.role === 'moderator' || data.user?.role === 'admin';
	const isApproved = data.moderation[0].status === 'approved';
	const isPending = data.moderation[0].status === 'pending';
	const isBeingReviewed = data.moderation[0].status === 'story_for_review';
	const canManage = isOwner || isModerator;
</script>

<PageHeader
	title={data.story.storyteller}
	subtitle={data.story.role === 'interview' ? 'Interview' : 'Monologue'}
/>
	<div class="container mx-auto space-y-10 pb-10">
	{#if !isApproved}
		<ModerationBanner moderation={data.moderation} />
	{/if}
	{#if isBeingReviewed || isApproved}
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
		{#if isApproved || isBeingReviewed}
			<Story data={data.story} />
		{/if}

		{#if data.permission || isOwner}
			<div class="mb-12">
				<Pending data={data.story} />
			</div>
		{/if}

		{#if isApproved}
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

	{#if data.permission || isOwner}
		<div
			class="sticky bottom-0 flex w-full flex-col items-center justify-center gap-y-4 border-t bg-background/95 py-4 backdrop-blur supports-[backdrop-filter]:bg-background/60 sm:flex-row sm:gap-x-10 sm:py-8"
		>
			{#if isOwner && isPending}
				{#if data.story.transcription}
					<Button href={`/story/${data.story.id}/transcription`} class="w-full sm:w-auto">
					<Eye class="mr-2 h-4 w-4" />
					Abrir Transcrição
					</Button>
				{:else}
					<Button href={`/story/${data.story.id}/edit-transcription`} class="w-full sm:w-auto">
					<Wand class="mr-2 h-4 w-4" />
					Gerar Transcrição
					</Button>
				{/if}
				<Button href={`/story/${data.story.id}/edit`} class="w-full sm:w-auto">
					<Pencil class="mr-2 h-4 w-4" />
					Editar História
				</Button>
			{/if}

			{#if !isOwner && isApproved}
				<Button href={`/story/${data.story.id}/colinking`} class="w-full sm:w-auto">
					<Network class="mr-2 h-4 w-4" />
					Colinking
				</Button>
			{/if}

			{#if isPending}
				<Button
					class="w-full sm:w-auto"
					on:click={() => data.story.transcription && goto(`/story/${data.story.id}/preview`)}
					disabled={!data.story.transcription}
					title={!data.story.transcription ? "Gerar transcrição primeiro para habilitar este passo" : ""}
					>
					<LayoutPanelTop class="mr-2 h-4 w-4" />
					Resumo e submissão da história
				</Button>
			{/if}


			{#if isModerator && isBeingReviewed}
				<Button 
					on:click={() => (openApproveDialog = true)} class="w-full sm:w-auto">
					<Check class="mr-2 h-4 w-4" />
					Aprovar
				</Button>
			{/if}

			{#if canManage && (isBeingReviewed || isApproved)}
				<Button
					variant="destructive"
					on:click={() => (openUnpublishDialog = true)}
					class="w-full sm:w-auto"
				>
					<MessageCircleCode class="mr-2 h-4 w-4" />
					Pedir Alterações
				</Button>
			{/if}

			{#if canManage}
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

<StoryApproveDialog storyId={data.story.id} storyOwner={data.story.user_id} data={data.approveForm} bind:open={openApproveDialog} />
<StoryDeleteDialog storyId={data.story.id} storyOwner={data.story.user_id} data={data.deleteForm} bind:open={openDeleteDialog} />
<StoryUnpublishDialog storyId={data.story.id} storyOwner={data.story.user_id} data={data.unpublishForm} bind:open={openUnpublishDialog}/>