<script lang="ts">
	import * as AlertDialog from '@/components/ui/alert-dialog';
	import { Button } from '@/components/ui/button';
	import { deleteHowToSchema, type DeleteHowToSchema } from '@/schemas/how-to';
	import { Trash } from 'lucide-svelte';
	import { superForm, type Infer, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient } from 'sveltekit-superforms/adapters';

	export let mapPinId: number;
	export let data: SuperValidated<Infer<DeleteHowToSchema>>;

	let open = false;

	const form = superForm(data, {
		validators: zodClient(deleteHowToSchema),
	});

	const { enhance } = form;
</script>

<Button variant="destructive" size="icon" on:click={() => (open = true)}>
	<Trash class="h-4 w-4" />
</Button>

<AlertDialog.Root bind:open>
	<form method="POST" action="?/delete" use:enhance class="hidden">
		<input type="hidden" name="id" value={mapPinId} />
	</form>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title>Are you absolutely sure?</AlertDialog.Title>
			<AlertDialog.Description>
				This action cannot be undone. This will permanently delete this map pin and remove its data
				from our servers.
			</AlertDialog.Description>
		</AlertDialog.Header>
		<AlertDialog.Footer>
			<AlertDialog.Cancel>Cancel</AlertDialog.Cancel>
			<AlertDialog.Action on:click={form.submit}>Continue</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
