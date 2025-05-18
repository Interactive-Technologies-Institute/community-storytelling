<script lang="ts">
	import InteractableImage from '@/components/interactable-image.svelte';
	import { Button } from '@/components/ui/button';
	import * as Card from '@/components/ui/card';
	import { FileInput } from '@/components/ui/file-input';
	import * as Form from '@/components/ui/form';
	import { Input } from '@/components/ui/input';
	import { Textarea } from '@/components/ui/textarea';
	import type { CreateHowToSchema } from '@/schemas/how-to';
	import { ArrowDown, ArrowUp, Trash } from 'lucide-svelte';
	import { fileProxy, type SuperForm } from 'sveltekit-superforms';
	import { type Infer } from 'sveltekit-superforms/adapters';

	export let form: SuperForm<Infer<CreateHowToSchema>>;
	export let index: number;

	const { form: formData } = form;

	// TODO: Fix this
	function removeStep() {
		$formData.steps = $formData.steps.filter((_, i) => i !== index);
	}

	function moveStepUp() {
		if (index === 0) return;
		const steps = $formData.steps;
		const step = steps[index];
		steps[index] = steps[index - 1];
		steps[index - 1] = step;
		$formData.steps = steps;
	}

	function moveStepDown() {
		if (index === $formData.steps.length - 1) return;
		const steps = $formData.steps;
		const step = steps[index];
		steps[index] = steps[index + 1];
		steps[index + 1] = step;
		$formData.steps = steps;
	}

	let image = fileProxy(form, `steps[${index}].image`);
	let imageUrl: string | null | undefined = $formData.steps[index].imageUrl;
	$: {
		if ($image.length > 0) {
			const img = $image.item(0);
			const reader = new FileReader();
			reader.onload = (e) => {
				imageUrl = e.target?.result as string | null | undefined;
			};
			reader.readAsDataURL(img!);
		} else {
			imageUrl = $formData.steps[index].imageUrl;
		}
	}
</script>

<Card.Root>
	<Card.Header>
		<div class="flex flex-row gap-x-4">
			<div class="flex flex-1 flex-col space-y-1.5">
				<Card.Title>
					Step {index + 1}
				</Card.Title>
				<Card.Description>Add details to this step</Card.Description>
			</div>
			<div class="flex flex-col gap-y-2 md:flex-row md:gap-x-2">
				{#if index !== 0}
					<Button variant="outline" size="icon" on:click={moveStepUp}>
						<ArrowUp class="h-4 w-4" />
					</Button>
				{/if}
				{#if index !== $formData.steps.length - 1}
					<Button variant="outline" size="icon" on:click={moveStepDown}>
						<ArrowDown class="h-4 w-4" />
					</Button>
				{/if}
				{#if $formData.steps.length > 3}
					<Button variant="destructive" size="icon" on:click={removeStep}>
						<Trash class="h-4 w-4" />
					</Button>
				{/if}
			</div>
		</div>
	</Card.Header>
	<Card.Content class="space-y-4">
		<Form.ElementField {form} name="steps[{index}].title">
			<Form.Control let:attrs>
				<Form.Label>Title*</Form.Label>
				<Input {...attrs} bind:value={$formData.steps[index].title} />
			</Form.Control>
			<Form.FieldErrors />
		</Form.ElementField>
		<Form.ElementField {form} name="steps[{index}].description">
			<Form.Control let:attrs>
				<Form.Label>Description*</Form.Label>
				<Textarea {...attrs} bind:value={$formData.steps[index].description} />
			</Form.Control>
			<Form.FieldErrors />
		</Form.ElementField>
		<div class="grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-2">
			<Form.ElementField {form} name="steps[{index}].image">
				<Form.Control let:attrs>
					<Form.Label>Cover Image*</Form.Label>
					<Card.Root class="aspect-[3/2] overflow-hidden">
						{#if imageUrl}
							<InteractableImage
								src={imageUrl}
								alt={`Step ${index + 1} Cover`}
								class="h-full w-full object-cover"
							/>
						{/if}
					</Card.Root>
					<FileInput {...attrs} bind:files={$image} accept="image/*" />
					<input hidden value={$formData.steps[index].imageUrl} name="steps[{index}].imageUrl" />
				</Form.Control>
				<Form.FieldErrors />
			</Form.ElementField>
		</div>
	</Card.Content>
</Card.Root>
