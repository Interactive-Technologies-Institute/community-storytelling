<script lang="ts">
	import InteractableImage from '@/components/interactable-image.svelte';
	import { Button } from '@/components/ui/button';
	import * as Card from '@/components/ui/card';
	import { FileInput } from '@/components/ui/file-input';
	import * as Form from '@/components/ui/form';
	import { Input } from '@/components/ui/input';
	import * as Select from '@/components/ui/select';
	import { TagInput } from '@/components/ui/tag-input';
	import { Textarea } from '@/components/ui/textarea';
	import { createHowToSchema, type CreateHowToSchema } from '@/schemas/how-to';
	import type { HowToDifficulty, HowToDuration } from '@/types/types';
	import type { Selected } from 'bits-ui';
	import { Loader2 } from 'lucide-svelte';
	import { fileProxy, superForm, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient, type Infer } from 'sveltekit-superforms/adapters';
	import StepForm from './step-form.svelte';

	export let data: SuperValidated<Infer<CreateHowToSchema>>;

	const form = superForm(data, {
		validators: zodClient(createHowToSchema),
		taintedMessage: true,
		dataType: 'json',
	});

	const { form: formData, enhance, submitting } = form;

	const difficultyOptions: Record<HowToDifficulty, { label: string }> = {
		easy: {
			label: 'Easy',
		},
		medium: {
			label: 'Medium',
		},
		hard: {
			label: 'Hard',
		},
	};
	$: selectedDifficulty = $formData.difficulty
		? {
				value: $formData.difficulty,
				label: difficultyOptions[$formData.difficulty].label,
			}
		: undefined;
	function getDifficultyFromValue(v: Selected<unknown>): HowToDifficulty {
		return v.value as HowToDifficulty;
	}

	const durationOptions: Record<HowToDuration, { label: string }> = {
		short: {
			label: 'Short',
		},
		medium: {
			label: 'Medium',
		},
		long: {
			label: 'Long',
		},
	};
	$: selectedDuration = $formData.duration
		? {
				value: $formData.duration,
				label: durationOptions[$formData.duration].label,
			}
		: undefined;
	function getDurationFromValue(v: Selected<unknown>): HowToDuration {
		return v.value as HowToDuration;
	}

	async function addStep() {
		$formData.steps = [...$formData.steps, { title: '', description: '' }];
	}

	const image = fileProxy(form, 'image');
	let imageUrl: string | null | undefined = $formData.imageUrl;
	$: {
		if ($image.length > 0) {
			const img = $image.item(0);
			const reader = new FileReader();
			reader.onload = (e) => {
				imageUrl = e.target?.result as string | null | undefined;
			};
			reader.readAsDataURL(img!);
		} else {
			imageUrl = $formData.imageUrl;
		}
	}
</script>

<form method="POST" enctype="multipart/form-data" use:enhance class="flex flex-col gap-y-10">
	<Card.Root>
		<Card.Header>
			<Card.Title>Information</Card.Title>
			<Card.Description>Add details to this how to</Card.Description>
		</Card.Header>
		<Card.Content class="space-y-4">
			<Form.Field {form} name="title">
				<Form.Control let:attrs>
					<Form.Label>Title*</Form.Label>
					<Input {...attrs} bind:value={$formData.title} />
					<Form.FieldErrors />
				</Form.Control>
			</Form.Field>
			<Form.Field {form} name="description">
				<Form.Control let:attrs>
					<Form.Label>Description*</Form.Label>
					<Textarea {...attrs} bind:value={$formData.description} />
					<Form.FieldErrors />
				</Form.Control>
			</Form.Field>
			<Form.Field {form} name="tags">
				<Form.Control let:attrs>
					<Form.Label>Tags*</Form.Label>
					<TagInput {...attrs} bind:value={$formData.tags} />
					<Form.FieldErrors />
				</Form.Control>
			</Form.Field>
			<div class="grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-2">
				<Form.Field {form} name="difficulty">
					<Form.Control let:attrs>
						<Form.Label>Difficulty*</Form.Label>
						<Select.Root
							{...attrs}
							selected={selectedDifficulty}
							onSelectedChange={(v) => {
								if (v) {
									$formData.difficulty = getDifficultyFromValue(v);
								}
							}}
						>
							<Select.Trigger {...attrs}>
								<Select.Value placeholder="Select" />
							</Select.Trigger>
							<Select.Content>
								<Select.Item value="easy">Easy</Select.Item>
								<Select.Item value="medium">Medium</Select.Item>
								<Select.Item value="hard">Hard</Select.Item>
							</Select.Content>
						</Select.Root>
						<Form.FieldErrors />
					</Form.Control>
				</Form.Field>
				<Form.Field {form} name="duration">
					<Form.Control let:attrs>
						<Form.Label>Duration*</Form.Label>
						<Select.Root
							{...attrs}
							selected={selectedDuration}
							onSelectedChange={(v) => {
								if (v) {
									$formData.duration = getDurationFromValue(v);
								}
							}}
						>
							<Select.Trigger {...attrs}>
								<Select.Value placeholder="Select" />
							</Select.Trigger>
							<Select.Content>
								<Select.Item value="short">Short</Select.Item>
								<Select.Item value="medium">Medium</Select.Item>
								<Select.Item value="long">Long</Select.Item>
							</Select.Content>
						</Select.Root>
						<Form.FieldErrors />
					</Form.Control>
				</Form.Field>
			</div>
			<div class="grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-2">
				<Form.Field {form} name="image">
					<Form.Control let:attrs>
						<Form.Label>Cover Image*</Form.Label>
						<Card.Root class="aspect-[3/2] overflow-hidden">
							{#if imageUrl}
								<InteractableImage
									src={imageUrl}
									alt="How To Cover"
									class="h-full w-full object-cover"
								/>
							{/if}
						</Card.Root>
						<FileInput {...attrs} bind:files={$image} accept="image/*" />
						<input hidden value={$formData.imageUrl} name="imageUrl" />
						<Form.FieldErrors />
					</Form.Control>
				</Form.Field>
			</div>
		</Card.Content>
	</Card.Root>
	<Form.Fieldset {form} name="steps">
		<Card.Root>
			<Card.Header>
				<Form.Legend><Card.Title>Steps*</Card.Title></Form.Legend>
				<Card.Description>Add steps to your how to</Card.Description>
			</Card.Header>
			<Card.Content class="space-y-4">
				{#each $formData.steps as _, i (i)}
					<StepForm {form} index={i} />
				{/each}
				<Button type="button" variant="outline" size="sm" class="mr-auto mt-2" on:click={addStep}>
					Add Step
				</Button>
			</Card.Content>
		</Card.Root>
	</Form.Fieldset>

	<div
		class="sticky bottom-0 flex w-full flex-row items-center justify-center gap-x-10 border-t bg-background/95 py-8 backdrop-blur supports-[backdrop-filter]:bg-background/60"
	>
		<Button variant="outline" href="/how-to">Cancel</Button>
		<Button type="submit" disabled={$submitting}>
			{#if $submitting}
				<Loader2 class="mr-2 h-4 w-4 animate-spin" />
			{/if}
			Submit
		</Button>
	</div>
</form>
