<script lang="ts">
	import * as AlertDialog from '@/components/ui/alert-dialog';
	import { approveStorySchema, type ApproveStorySchema } from '@/schemas/story';
	import { superForm, type Infer, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient } from 'sveltekit-superforms/adapters';

	export let open = false;
	export let storyId: number;
	export let storyOwner: string;
	export let data: SuperValidated<Infer<ApproveStorySchema>>;

	const form = superForm(data, {
		validators: zodClient(approveStorySchema),
	});

	const { enhance } = form;
</script>

<AlertDialog.Root bind:open>
	<form method="POST" action="?/approve" use:enhance>
		<input type="hidden" name="id" value={storyId} />
		<input type="hidden" name="userId" value={storyOwner} />
	</form>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title>Você tem certeza?</AlertDialog.Title>
			<AlertDialog.Description>
				Esta ação fará com que esta história seja pública.
			</AlertDialog.Description>
		</AlertDialog.Header>
		<AlertDialog.Footer>
			<AlertDialog.Cancel>Cancelar</AlertDialog.Cancel>
			<AlertDialog.Action on:click={form.submit}>Continuar</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
