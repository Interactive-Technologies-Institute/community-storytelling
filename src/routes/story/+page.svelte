<script lang="ts">
	import PageHeader from '@/components/page-header.svelte';
	import TagFilterButton from '@/components/tag-filter-button.svelte';
	import { Button } from '@/components/ui/button';
	import { Input } from '@/components/ui/input';
	import { PlusCircle } from 'lucide-svelte';
	import SortButton from './../../lib/components/sort-button.svelte';
	import StoryItem from './_components/story-item.svelte';
	import { queryParam } from 'sveltekit-search-params';
	import { arrayQueryParam, stringQueryParam } from '@/utils';
	import { sortField, sortDirection } from "@/stores/sortStore";

	export let data;

	const userRole = data.userRole;
	const userId = data.userId;

	const search = queryParam('s', stringQueryParam(), {
		debounceHistory: 500,
	});

	const tags = queryParam('tags', arrayQueryParam());
</script>

<PageHeader title="Histórias" subtitle="Lê histórias da Curraleira/Horizonte" />
<div class="container mx-auto flex flex-row justify-between gap-x-2">
	<div class="flex flex-1 flex-row gap-x-2 sm:gap-x-4 md:flex-auto">
		<Input placeholder="Pesquisa..." class="flex-1 sm:max-w-64" bind:value={$search}></Input>
		<TagFilterButton tags={data.tags} bind:filterValues={$tags} />
		<SortButton />
	</div>
	<Button href="/story/create" class="w-10 p-0 sm:w-auto sm:px-4 sm:py-2">
		<PlusCircle class="h-4 w-4 sm:mr-2" />
		<span class="sr-only sm:not-sr-only">Criar História</span>
	</Button>
</div>
<div
  class="container mx-auto grid grid-cols-1 gap-6 py-10 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4"
>
  {#each [...data.stories]
    .filter(story => {
      if (story.moderation_status === "approved") return true;

      if (
        story.moderation_status === "pending" &&
        story.user_id === userId
      ) {
        return true;
      }

      if (
        story.moderation_status === "story_for_review" &&
        (userRole === "moderator" || userRole === "admin")
      ) {
        return true;
      }

      return false;
    })
    .sort((a, b) => {
		const statusOrder = {
			pending: 0,
			story_for_review: 1,
			changes_requested: 2,
			approved: 3,
			rejected: 4,
		};

		if (statusOrder[a.moderation_status] < statusOrder[b.moderation_status]) return -1;
		if (statusOrder[a.moderation_status] > statusOrder[b.moderation_status]) return 1;

		const field = $sortField;
		const dir = $sortDirection === "asc" ? 1 : -1;

		if (a[field] < b[field]) return -1 * dir;
		if (a[field] > b[field]) return 1 * dir;
		return 0;
	}) as story}
    <StoryItem {story} />
  {/each}
</div>
