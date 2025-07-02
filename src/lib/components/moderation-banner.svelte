<script lang="ts">
	import type { ModerationInfo } from '@/types/types';
	import { Info } from 'lucide-svelte';
	import ModerationDetails from './moderation-details.svelte';
	import * as Alert from './ui/alert';
	import { Button } from './ui/button';

	export let moderation: ModerationInfo[];

	$: latestModeration = moderation[0];
	let variant: Alert.Variant = 'default';
	$: variant = latestModeration.status === 'rejected' ? 'destructive' : 'default';
	let openSheet = false;
</script>

<Alert.Root {variant} class="mx-auto max-w-xl">
	<Info class="mr-2 h-4 w-4" />
	<Alert.Title>
		{#if latestModeration.status === 'rejected'}
			Rejected (marked for deletetion)
		{:else if latestModeration.status === 'pending'}
			Pending Moderation
		{:else if latestModeration.status === 'changes_requested'}
			Changes Requested
		{/if}
	</Alert.Title>
	<Alert.Description>{latestModeration.comment}</Alert.Description>
	<Button size="sm" variant="outline" class="mt-2" on:click={() => (openSheet = true)}>
		More Details
	</Button>
</Alert.Root>

<ModerationDetails {moderation} bind:open={openSheet} />

