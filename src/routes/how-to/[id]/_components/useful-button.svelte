<script lang="ts">
	import { Button } from '@/components/ui/button';
	import { toggleHowToUsefulSchema, type ToggleHowToUsefulSchema } from '@/schemas/how-to';
	import { cn } from '@/utils';
	import { Bookmark } from 'lucide-svelte';
	import { tick } from 'svelte';
	import { superForm, type Infer, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient } from 'sveltekit-superforms/adapters';

	export let count: number;
	export let data: SuperValidated<Infer<ToggleHowToUsefulSchema>>;

	const form = superForm(data, {
		validators: zodClient(toggleHowToUsefulSchema),
		invalidateAll: 'force',
		onUpdate: ({ result }) => {
			if (result.type === 'failure') {
				$formData.value = !$formData.value;
				count += $formData.value ? 1 : -1;
			}
		},
	});

	const { form: formData, enhance, submit } = form;

	async function toggleUseful() {
		$formData.value = !$formData.value;
		count += $formData.value ? 1 : -1;
		await tick();
		submit();
	}
</script>

<form method="POST" action="?/toggleUseful" use:enhance>
	<input type="hidden" name="value" value={$formData.value} />
	<Button type="button" on:click={toggleUseful} variant="outline" size="sm">
		<Bookmark class={cn('mr-2 h-4 w-4', { 'fill-foreground': $formData.value })} />
		{#if $formData.value}
			Marked as useful
		{:else}
			Mark as useful
		{/if}
		<span class="ml-4 font-mono text-xs">{count}</span>
	</Button>
</form>
