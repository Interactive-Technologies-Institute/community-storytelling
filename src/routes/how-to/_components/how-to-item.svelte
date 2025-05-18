<script lang="ts">
	import { page } from '$app/stores';
	import { AspectRatio } from '@/components/ui/aspect-ratio';
	import { Badge } from '@/components/ui/badge';
	import { Button } from '@/components/ui/button';
	import { Card } from '@/components/ui/card';
	import type { HowTo } from '@/types/types';
	import { Tag } from 'lucide-svelte';

	export let howTo: HowTo;

	const moderationStatusLabels = {
		pending: 'Pending',
		approved: 'Approved',
		changes_requested: 'Changes Requested',
		rejected: 'Rejected',
	};

	$: imageUrl = $page.data.supabase.storage.from('howtos').getPublicUrl(howTo.image).data.publicUrl;
</script>

<a href="/how-to/{howTo.id}">
	<Card class="relative overflow-hidden">
		<AspectRatio ratio={3 / 2}>
			{#if imageUrl}
				<img src={imageUrl} alt="How To Cover" class="h-full w-full object-cover" />
				{#if howTo.moderation_status !== 'approved'}
					<Badge
						class="absolute right-2 top-2"
						variant={howTo.moderation_status === 'rejected' ? 'destructive' : 'secondary'}
					>
						{moderationStatusLabels[howTo.moderation_status]}
					</Badge>
				{/if}
			{/if}
		</AspectRatio>
		<div class="flex flex-col px-4 py-3">
			<div class="mb-5">
				<h2 class="line-clamp-2 text-lg font-medium">{howTo.title}</h2>
				<p class="line-clamp-2 text-muted-foreground">{howTo.description}</p>
			</div>
			<div class="flex flex-wrap gap-2">
				{#each howTo.tags as tag}
					<Button variant="secondary" size="sm" href="/how-to?tags={tag}">
						<Tag class="mr-2 h-4 w-4" />
						{tag}
					</Button>
				{/each}
			</div>
		</div>
	</Card>
</a>
