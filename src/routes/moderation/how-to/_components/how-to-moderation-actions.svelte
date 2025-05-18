<script lang="ts">
	import * as Form from '$lib/components/ui/form';
	import { Button } from '@/components/ui/button';
	import * as Dialog from '@/components/ui/dialog';
	import * as DropdownMenu from '@/components/ui/dropdown-menu';
	import { Textarea } from '@/components/ui/textarea';
	import {
		updateModerationInfoSchema,
		type UpdateModerationInfoSchema,
	} from '@/schemas/moderation-info';
	import { Ellipsis } from 'lucide-svelte';
	import { superForm, type Infer, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient } from 'sveltekit-superforms/adapters';

	export let id: number;
	export let userId: string;
	export let data: SuperValidated<Infer<UpdateModerationInfoSchema>>;

	const form = superForm(data, {
		validators: zodClient(updateModerationInfoSchema),
		onResult: (event) => {
			if (event.result.type === 'success') {
				openApproveDialog = false;
				openRejectDialog = false;
				openRequestChangesDialog = false;
			}
		},
	});

	const { form: formData, enhance } = form;

	let openApproveDialog = false;
	let openRejectDialog = false;
	let openRequestChangesDialog = false;
</script>

<DropdownMenu.Root>
	<DropdownMenu.Trigger asChild let:builder>
		<Button variant="ghost" builders={[builder]} size="icon" class="relative h-8 w-8 p-0">
			<span class="sr-only">Open menu</span>
			<Ellipsis class="h-4 w-4" />
		</Button>
	</DropdownMenu.Trigger>
	<DropdownMenu.Content>
		<DropdownMenu.Item href="/how-to/{id}">Open</DropdownMenu.Item>
		<DropdownMenu.Separator />
		<DropdownMenu.Group>
			<DropdownMenu.Label>Actions</DropdownMenu.Label>
			<DropdownMenu.Item on:click={() => (openApproveDialog = true)}>Approve</DropdownMenu.Item>
			<DropdownMenu.Item on:click={() => (openRejectDialog = true)}>Reject</DropdownMenu.Item>
			<DropdownMenu.Item on:click={() => (openRequestChangesDialog = true)}>
				Request Changes
			</DropdownMenu.Item>
		</DropdownMenu.Group>
	</DropdownMenu.Content>
</DropdownMenu.Root>

<Dialog.Root bind:open={openApproveDialog}>
	<Dialog.Content class="sm:max-w-[425px]">
		<Dialog.Header>
			<Dialog.Title>Approve How To</Dialog.Title>
			<Dialog.Description>Are you sure you want to approve this How To?</Dialog.Description>
		</Dialog.Header>
		<form method="POST" use:enhance>
			<input type="hidden" name="ref_id" value={id} />
			<input type="hidden" name="user_id" value={userId} />
			<input type="hidden" name="status" value="approved" />
			<Form.Field {form} name="comment">
				<Form.Control let:attrs>
					<Form.Label>Comment</Form.Label>
					<Textarea {...attrs} bind:value={$formData.comment} />
				</Form.Control>
				<Form.Description>Leave a comment for the User.</Form.Description>
				<Form.FieldErrors />
			</Form.Field>
		</form>
		<Dialog.Footer>
			<Button variant="secondary" on:click={() => (openApproveDialog = false)}>Cancel</Button>
			<Button type="submit" on:click={form.submit}>Approve</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>

<Dialog.Root bind:open={openRejectDialog}>
	<Dialog.Content class="sm:max-w-[425px]">
		<Dialog.Header>
			<Dialog.Title>Reject How To</Dialog.Title>
			<Dialog.Description>Are you sure you want to reject this How To?</Dialog.Description>
		</Dialog.Header>
		<form method="POST" use:enhance>
			<input type="hidden" name="ref_id" value={id} />
			<input type="hidden" name="user_id" value={userId} />
			<input type="hidden" name="status" value="rejected" />
			<Form.Field {form} name="comment">
				<Form.Control let:attrs>
					<Form.Label>Comment</Form.Label>
					<Textarea {...attrs} bind:value={$formData.comment} />
				</Form.Control>
				<Form.Description>Leave a comment for the User.</Form.Description>
				<Form.FieldErrors />
			</Form.Field>
		</form>
		<Dialog.Footer>
			<Button variant="secondary" on:click={() => (openRejectDialog = false)}>Cancel</Button>
			<Button type="submit" on:click={form.submit}>Reject</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>

<Dialog.Root bind:open={openRequestChangesDialog}>
	<Dialog.Content class="sm:max-w-[425px]">
		<Dialog.Header>
			<Dialog.Title>Request Changes</Dialog.Title>
			<Dialog.Description
				>Are you sure you want to request changes for this How To?</Dialog.Description
			>
		</Dialog.Header>
		<form method="POST" use:enhance>
			<input type="hidden" name="ref_id" value={id} />
			<input type="hidden" name="user_id" value={userId} />
			<input type="hidden" name="status" value="changes_requested" />
			<Form.Field {form} name="comment">
				<Form.Control let:attrs>
					<Form.Label>Comment</Form.Label>
					<Textarea {...attrs} bind:value={$formData.comment} />
				</Form.Control>
				<Form.Description>Leave a comment for the User.</Form.Description>
				<Form.FieldErrors />
			</Form.Field>
		</form>
		<Dialog.Footer>
			<Button variant="secondary" on:click={() => (openRequestChangesDialog = false)}>
				Cancel
			</Button>
			<Button type="submit" on:click={form.submit}>Request Changes</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>
