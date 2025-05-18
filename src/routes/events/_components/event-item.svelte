<script lang="ts">
	import { page } from '$app/stores';
	import { AspectRatio } from '@/components/ui/aspect-ratio';
	import { Badge } from '@/components/ui/badge';
	import { Button } from '@/components/ui/button';
	import { Card } from '@/components/ui/card';
	import type { Event } from '@/types/types';
	import dayjs from 'dayjs';
	import { Tag } from 'lucide-svelte';

	export let event: Event;

	const moderationStatusLabels = {
		pending: 'Pending',
		approved: 'Approved',
		changes_requested: 'Changes Requested',
		rejected: 'Rejected',
	};

	$: imageUrl = $page.data.supabase.storage.from('events').getPublicUrl(event.image).data.publicUrl;
</script>

<a href="/events/{event.id}">
	<Card class="relative overflow-hidden">
		<AspectRatio ratio={3 / 2}>
			{#if imageUrl}
				<img src={imageUrl} alt="Event Cover" class="h-full w-full object-cover" />
				{#if event.moderation_status !== 'approved'}
					<Badge
						class="absolute right-2 top-2"
						variant={event.moderation_status === 'rejected' ? 'destructive' : 'secondary'}
					>
						{moderationStatusLabels[event.moderation_status]}
					</Badge>
				{/if}
			{/if}
		</AspectRatio>
		<div class="flex flex-col px-4 py-3">
			<div class="mb-5">
				<p class="font-medium leading-none">
					{dayjs(event.date).format(
						dayjs(event.date).year() === dayjs().year()
							? 'ddd, MM/DD [at] HH:mm'
							: 'ddd, MM/DD/YYYY [at] HH:mm'
					)}
					•
					{event.location}
				</p>
				<h2 class="line-clamp-2 text-lg font-medium">{event.title}</h2>
				<p class="line-clamp-2 text-muted-foreground">{event.description}</p>
			</div>
			<div class="flex flex-wrap gap-2">
				{#each event.tags as tag}
					<Button variant="secondary" size="sm" href="/events?tags={tag}">
						<Tag class="mr-2 h-4 w-4" />
						{tag}
					</Button>
				{/each}
			</div>
		</div>
	</Card>
</a>
