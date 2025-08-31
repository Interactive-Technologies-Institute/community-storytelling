<script lang="ts">
	import * as AlertDialog from '@/components/ui/alert-dialog';
	import { Button } from '@/components/ui/button';
	import * as DropdownMenu from '@/components/ui/dropdown-menu';
	import { updateUserRoleSchema, type UpdateUserRoleSchema } from '@/schemas/user-role';
	import type { UserRole } from '@/types/types';
	import { Ellipsis } from 'lucide-svelte';
	import { type Infer, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient } from 'sveltekit-superforms/adapters';
	import { superForm } from 'sveltekit-superforms/client';

	export let id: string;
	export let currentRole: UserRole;
	export let data: SuperValidated<Infer<UpdateUserRoleSchema>>;

	let showConfirmDialog = false;
	$: selectedRole = currentRole;

	const form = superForm(data, {
		validators: zodClient(updateUserRoleSchema),
		onResult: (event) => {
			if (event.result.type === 'success') {
				showConfirmDialog = false;
			}
		},
	});

	const { enhance } = form;

	function handleRoleChange(role: string | undefined) {
		if (!role) return;
		selectedRole = role as UserRole;
		showConfirmDialog = true;
	}
</script>

<DropdownMenu.Root>
	<DropdownMenu.Trigger asChild let:builder>
		<Button variant="ghost" builders={[builder]} size="icon" class="relative h-8 w-8 p-0">
			<span class="sr-only">Open menu</span>
			<Ellipsis class="h-4 w-4" />
		</Button>
	</DropdownMenu.Trigger>
	<DropdownMenu.Content>
		<DropdownMenu.Item href="/users/{id}">Perfil</DropdownMenu.Item>
		<DropdownMenu.Separator />
		<DropdownMenu.RadioGroup value={currentRole} onValueChange={handleRoleChange}>
			<DropdownMenu.Label>Roles</DropdownMenu.Label>
			<DropdownMenu.RadioItem value="user">User</DropdownMenu.RadioItem>
			<DropdownMenu.RadioItem value="moderator">Moderador</DropdownMenu.RadioItem>
			<DropdownMenu.RadioItem value="admin">Admin</DropdownMenu.RadioItem>
		</DropdownMenu.RadioGroup>
	</DropdownMenu.Content>
</DropdownMenu.Root>

<AlertDialog.Root bind:open={showConfirmDialog}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title>Confirm Role Change</AlertDialog.Title>
			<AlertDialog.Description>
				Are you sure you want to change this user's role to {selectedRole}?
			</AlertDialog.Description>
		</AlertDialog.Header>
		<AlertDialog.Footer>
			<AlertDialog.Cancel>Cancel</AlertDialog.Cancel>
			<form method="POST" use:enhance>
				<input type="hidden" name="userId" value={id} />
				<input type="hidden" name="role" value={selectedRole} />
				<AlertDialog.Action type="submit">Confirm</AlertDialog.Action>
			</form>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
