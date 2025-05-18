<script lang="ts">
	import type { ModerationStatus } from '@/types/types';
	import { typeMap } from './how-to-moderation-status-map';

	export let status: ModerationStatus;

	$: ({ label, icon } = typeMap[status]);
</script>

<div class="flex items-center">
	<svelte:component this={icon} class="mr-2 h-4 w-4 text-muted-foreground" />
	<span>{label}</span>
</div>
