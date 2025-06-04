<script lang="ts">
	import * as Avatar from '@/components/ui/avatar';
	import { Button } from '@/components/ui/button';
	import * as Card from '@/components/ui/card';
	import { FileInput } from '@/components/ui/file-input';
	import * as Form from '@/components/ui/form';
	import { Input } from '@/components/ui/input';
	import { updateUserProfileSchema, type UpdateUserProfileSchema } from '@/schemas/user-profile';
	import { firstAndLastInitials } from '@/utils';
	import { Loader2 } from 'lucide-svelte';
	import { fileProxy, superForm, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient, type Infer } from 'sveltekit-superforms/adapters';

	export let data: SuperValidated<Infer<UpdateUserProfileSchema>>;

	const form = superForm(data, {
		validators: zodClient(updateUserProfileSchema),
		taintedMessage: true,
		resetForm: false,
	});

	const { form: formData, enhance, submitting, isTainted, tainted } = form;

	const avatar = fileProxy(form, 'avatar');
	let avatarUrl: string | null | undefined = $formData.avatarUrl;
	$: {
		if ($avatar.length > 0) {
			const img = $avatar.item(0);
			const reader = new FileReader();
			reader.onload = (e) => {
				avatarUrl = e.target?.result as string | null | undefined;
			};
			reader.readAsDataURL(img!);
		} else {
			avatarUrl = $formData.avatarUrl;
		}
	}

	let resettingAvatar = false;

	function resetAvatar() {
		if (resettingAvatar) return;
		
		resettingAvatar = true;
		avatar.set(null);
		avatarUrl = null;
		$formData.avatarReset = true;
	}

</script>

<form method="POST" enctype="multipart/form-data" action="?/updateProfile" use:enhance={{
		onResult: ({ result }) => {
			if (result.type === 'success' || result.type === 'failure') {
				resettingAvatar = false;
			}
		}
	}}>
	<Card.Root>
		<Card.Header>
			<Card.Title>Edit Profile</Card.Title>
			<Card.Description>Lorem Ipsum</Card.Description>
		</Card.Header>
		<Card.Content>
			<div class="max-w-2xl space-y-4">
				<Form.Field {form} name="display_name">
					<Form.Control let:attrs>
						<Form.Label>Name*</Form.Label>
						<Input {...attrs} bind:value={$formData.display_name} />
						<Form.FieldErrors />
					</Form.Control>
				</Form.Field>
				<Form.Field {form} name="description">
					<Form.Control let:attrs>
						<Form.Label>Description</Form.Label>
						<Input {...attrs} bind:value={$formData.description} />
						<Form.FieldErrors />
					</Form.Control>
				</Form.Field>
				<Form.Field {form} name="avatar">
					<Form.Control let:attrs>
						<Form.Label>Avatar</Form.Label>
						<div class="relative flex aspect-[3/2] items-center justify-center p-4">
							<Avatar.Root class="h-20 w-20 md:h-40 md:w-40">
								<Avatar.Image src={avatarUrl} alt="User avatar" />
								<Avatar.Fallback>{firstAndLastInitials($formData.display_name)}</Avatar.Fallback>
							</Avatar.Root>
							<Button
								type="button"
								variant="destructive"
								size="sm"
								class="absolute right-2"
								on:click={resetAvatar}
								disabled={resettingAvatar}>
								Reset Avatar
							</Button>
						</div>
						<FileInput {...attrs} bind:files={$avatar} accept="image/*" />
						<input hidden value={$formData.avatarUrl} name="avatarUrl" />
						<input hidden name="avatarReset" value={$formData.avatarReset ? 'true' : 'false'} />
						<input hidden name="avatarPath" value={$formData.avatarPath ?? ''} />
						<Form.FieldErrors />
					</Form.Control>
				</Form.Field>
			</div>
		</Card.Content>
		<Card.Footer>
			<Button type="submit" disabled={$submitting || !isTainted($tainted)}>
				{#if $submitting}
					<Loader2 class="mr-2 h-4 w-4 animate-spin" />
				{/if}
				Save Settings
			</Button>
		</Card.Footer>
	</Card.Root>
</form>
