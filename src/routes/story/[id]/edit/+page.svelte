<script lang="ts">
	import { applyAction, deserialize } from '$app/forms';
	import { Button } from '$lib/components/ui/button';
	import * as Form from '$lib/components/ui/form';
	import { editStorySchema, type EditStorySchema } from '$lib/schemas/edit-story';

	import { superForm, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient, type Infer } from 'sveltekit-superforms/adapters';

	import Input from '$lib/components/ui/input/input.svelte';

	import { ArrowLeft, ArrowRight, ArrowUp, Camera, Check, Loader2, Mic, Video } from 'lucide-svelte';

	import Map from '../../../map/_components/map.svelte';
	import Marker from '../../../map/_components/marker.svelte';
	
	let mapCenter = { lat: 38.7382, lng: -9.1212 };
	let markerPosition: { lat: number; lng: number } | null = null;

	let altImg = 'Taking notes';

	let page = 1;

	export let data: {
        editForm: SuperValidated<Infer<EditStorySchema>>
    };

	const form = superForm(data.editForm, {
		validators: zodClient(editStorySchema),
		taintedMessage: true,
		dataType: 'json',
	});

	const { form: formData, errors } = form;

	$formData.pinColor = $formData.pinColor ?? '#ff0000';

	let editStoryForm: HTMLFormElement;

	$: submitting = false;

	let search = '';
	let results: { id: string; display_name: string }[] = [];
	let selectedMembers: { id: string; display_name: string }[] = [];

    $: if (data.editForm.data.coauthors && data.editForm.data.extra?.users) {
        selectedMembers = data.editForm.data.coauthors
            .map(id => data.editForm.data.extra!.users.find(u => u.id === id))
            .filter(Boolean) as { id: string; display_name: string }[];
    }

	$: results = search.trim()
		? (data.editForm.data.extra?.users ?? []).filter(u =>
			u.display_name.toLowerCase().includes(search.toLowerCase())
		)
		: [];

  	$: $formData.coauthors = selectedMembers.map(m => m.id);

	function addMember(user: { id: string; display_name: string }) {
		if (!selectedMembers.find(m => m.id === user.id)) {
		selectedMembers = [...selectedMembers, user];
		}
		search = '';
		results = [];
	}

	function removeMember(id: string) {
		selectedMembers = selectedMembers.filter(m => m.id !== id);
	}

    $: if ($formData.lat != null && $formData.lng != null) {
        markerPosition = { lat: $formData.lat, lng: $formData.lng };
    }

	function handleMapClick(event: CustomEvent<{ lat: number; lng: number }>) {
		markerPosition = event.detail;
		$formData.lat = event.detail.lat;
		$formData.lng = event.detail.lng;
	}

	async function submitEditStoryForm(event: Event) {
		submitting = true;
		event.preventDefault();

		$formData.tags = [
			$formData.year?.toString() ?? '',
			$formData.tags[0]
		]

		const form = event.currentTarget as HTMLFormElement;

		const formData = new FormData(form);

		let newFormData = new FormData();

		let coauthorsArray: string[] = [];

		const rawCoauthors = $formData.coauthors as unknown;

		if (Array.isArray(rawCoauthors)) {
			coauthorsArray = rawCoauthors as string[];
		}
	
		else if (typeof rawCoauthors === 'string') {
			coauthorsArray = (rawCoauthors as string).split(',').map(s => s.trim()).filter(Boolean);
		}

		coauthorsArray.forEach(id => newFormData.append('coauthors', id));

		$formData.tags.forEach(tag => {
			if (tag) newFormData.append('tags', tag);
		});


		for (let [key, value] of formData.entries()) {
			if (key !== 'coauthors' && key !== 'tags') {
				newFormData.append(key, value);
			}
		}

		const response = await fetch('?/editStory', {
			method: 'POST',
			body: newFormData,
			headers: {
				'x-sveltekit-action': 'true',
			},
		});

		const result = deserialize(await response.text());
		if (result.status === 200) {
			submitting = false;
		}

		applyAction(result);
	}

	function triggerFileInput(id: string) {
		(document.getElementById(id) as HTMLElement | null)?.click();
	}
</script>

<div class="container mx-auto space-y-10 pb-10">
	<form
		method="POST"
		action="?/editStory"
		bind:this={editStoryForm}
		on:submit|preventDefault={submitEditStoryForm}
		enctype="multipart/form-data"
		class="flex flex-col gap-y-10"
	>
		<div class="page" class:show={page === 1}>
			<img class="mx-auto" src="/app_images/taking_notes.png" alt={altImg} width={280} />
			<Form.Field {form} name="storyteller" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-3xl font-semibold tracking-tight transition-colors"
						>Qual é o nome da pessoa a ser entrevistada?</Form.Label
					>
					<div class="flex flex-col items-center gap-3 pt-3">
						<Input class="w-auto" {...attrs} bind:value={$formData.storyteller} on:blur={() => form.validate('storyteller')} on:input={() => form.validate('storyteller')}/>
						<Form.FieldErrors />
						<Button class="p-2 bg-green-600 text-white hover:bg-green-700" type="button" on:click={() => (page = 3)} disabled={$formData.storyteller.length < 2 || $formData.storyteller.length > 100}>
							<ArrowRight />
						</Button>
					</div>
				</Form.Control>
			</Form.Field>
		</div>
		<div class="page" class:show={page === 2}>
			<h2 class="pb-2 text-3xl font-semibold tracking-tight text-center">
				Quem desenvolveu esta história contigo?
			</h2>

			<input
				type="text"
				placeholder="Search users..."
				bind:value={search}
				class="w-full p-2 border rounded mt-4"
			/>

			{#if results.length > 0}
				<!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
				<ul class="results-list">
					<!-- svelte-ignore a11y-click-events-have-key-events -->
					{#each results as user}
						<li
							class="results-item"
							on:click={() => addMember(user)}
						>
							{user.display_name}
						</li>
					{/each}
				</ul>
			{/if}

			{#if selectedMembers.length > 0}
				<h3 class="mt-4 font-semibold">Selected Members:</h3>
				<ul class="mt-2 space-y-2">
					{#each selectedMembers as member}
						<li class="flex justify-between items-center border p-2 rounded">
							<span>{member.display_name}</span>
							<button type="button" on:click={() => removeMember(member.id)}>✕</button>
						</li>
					{/each}
				</ul>
			{/if}

			<input
				type="hidden"
				name="coauthors"
				value={selectedMembers.map(m => m.id).join(',')}
			/>
			<div class="flex justify-center pt-6">
				<Button
					class="p-2 bg-green-600 text-white hover:bg-green-700"
					on:click={() => (page = 3)}
				>
					<ArrowRight />
				</Button>
			</div>
		</div>
		<div class="page" class:show={page === 3}>
			<img class="mx-auto" src="/app_images/taking_notes.png" alt={altImg} width={280} />
			<Form.Field {form} name="year" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-3xl font-semibold tracking-tight transition-colors"
						>Se existe, em que período é que esta história se foca?</Form.Label
					>
					<div class="flex flex-col items-center gap-3 pt-3">
						<Input class="w-auto" {...attrs} bind:value={$formData.year} on:blur={() => form.validate('year')} on:input={() => form.validate('year')} />
						<Form.FieldErrors />
							<Button class="p-2 bg-green-600 text-white hover:bg-green-700" type="button" on:click={() => (page = 4)} disabled={$formData.year !== '' && $formData.year !== undefined && (isNaN(Number($formData.year)) || Number($formData.year) < 1950 || Number($formData.year) > 2030)}><ArrowRight />
							</Button>
					</div>
				</Form.Control>
			</Form.Field>
			<Form.Field {form} hidden name="tags" class="text-center">
				<Form.Control let:attrs>
					<input hidden name="tags" bind:value={$formData.tags[1]} />
					<Form.FieldErrors />
				</Form.Control>
			</Form.Field>
		</div>
		<div class="page" class:show={page === 4}>
			<h2 class="pb-4 text-center text-3xl font-semibold">
				A história está relacionada com um local específico? Se sim, escolhe esse local no mapa.
			</h2>

			<div class="h-[600px] w-full max-w-2xl mx-auto rounded shadow-lg">
				<Map lng={mapCenter.lng}
					lat={mapCenter.lat}
					zoom={14}
					on:mapClick={handleMapClick}>

					{#if markerPosition}
						<Marker lng={markerPosition.lng} lat={markerPosition.lat} disableClick={true} marker_color={$formData.pinColor} />
					{/if}
				</Map>
			</div>

			<div class="mt-4 flex flex-col items-center gap-2">
				<label for="pinColor" class="text-lg font-medium">Escolhe a cor do marcador:</label>
				<input
					type="color"
					id="pinColor"
					bind:value={$formData.pinColor}
					class="w-12 h-12 rounded-full border p-0"
				/>
			</div>

			<input type="hidden" name="pinColor" value={$formData.pinColor} />
			<input type="hidden" name="lat" value={$formData.lat ?? ''} />
			<input type="hidden" name="lng" value={$formData.lng ?? ''} />

			<div class="flex justify-center pt-6">
				<Button type="submit">
					{#if submitting}
						<Loader2 class="mr-2 h-4 w-4 animate-spin" />
					{/if}
					Guardar Alterações
				</Button>
			</div>
		</div>
	</form>
	{#if page !== 1}
		<div
			class="sticky bottom-0 flex w-full flex-col items-center justify-center gap-y-4 border-t bg-background/95 py-4 backdrop-blur supports-[backdrop-filter]:bg-background/60 sm:flex-row sm:gap-x-10 sm:py-8"
		>
			<Button
				variant="outline"
				on:click={() => (page > 1 ? (page = page - 1) : page)}
				class="w-full sm:w-auto"
			>
				<ArrowLeft class="mr-2 h-4 w-4" />
				Voltar
			</Button>
		</div>
	{/if}
</div>

<style>
	.page {
		display: none;
	}
	.page.show {
		display: block;
	}
	.no-pointer {
		pointer-events: none;
	}
	.results-list {
		background-color: black;
		color: white;
		border-radius: 0.25rem;
		padding: 0.25rem 0;
		margin-top: 0.5rem;
		max-height: 200px;
		overflow-y: auto;
		list-style: none;
		box-shadow: 0 4px 6px rgba(0,0,0,0.1);
		z-index: 50;
		border: 1px solid white;
	}

	.results-item {
		padding: 0.5rem 1rem;
		cursor: pointer;
		white-space: nowrap;        
		overflow: hidden;           
		text-overflow: ellipsis;   
	}

	.results-item:hover {
		background-color: #333;
	}
</style>
