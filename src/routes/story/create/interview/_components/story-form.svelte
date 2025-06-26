<script lang="ts">
	import { applyAction, deserialize } from '$app/forms';
	import { PUBLIC_CLOUDINARY_CLOUD_NAME, PUBLIC_GOOGLE_MAPS_KEY } from '$env/static/public';
	import { Button } from '$lib/components/ui/button';
	import * as Carousel from '$lib/components/ui/carousel/index.js';
	import * as Form from '$lib/components/ui/form';
	import { createStorySchema, type CreateStorySchema } from '$lib/schemas/story';

	import { superForm, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient, type Infer } from 'sveltekit-superforms/adapters';

	import Input from '$lib/components/ui/input/input.svelte';
	import { onMount } from 'svelte';

	import { ArrowLeft, ArrowRight, Camera, Check, Loader2, Mic, Video } from 'lucide-svelte';

	import { Loader } from '@googlemaps/js-api-loader';

	let mapContainer: HTMLDivElement;
	let map: google.maps.Map;
	let marker;

	const apiKey = PUBLIC_GOOGLE_MAPS_KEY;

	/*const questions = [
		'Fale-nos de si (o seu nome, idade e uma característica sobre si)',
		'Se pudesse resumir o que o bairro Horizonte significa para si, o que diria? (Se não tiver quaisquer relação com o bairro Horizonte, fale do seu próprio bairro)',
		'Que lugar do dia a dia ou pessoa faz o bairro, mencionado por si, ter um sentimento de casa?',
		'Descreva uma memória importante que tenha do seu bairro escolhido',
		'Como vê o bairro daqui a cinco ou dez anos?',
	];*/

	const questions = [
		'Placeholder 1',
		'Placeholder 2',
		'Placeholder 3',
	];

	let altImg = 'Taking notes';

	let page = 1;

	export let data: SuperValidated<Infer<CreateStorySchema>>;

	const form = superForm(data, {
		validators: zodClient(createStorySchema),
		taintedMessage: true,
		dataType: 'json',
	});

	const { form: formData, errors } = form;

	$formData.role = 'interview';
	$formData.tags[0] = 'Interview';

	let recordingType = ''; // 'video' or 'audio'
	let firstImageTaken = false;
	let secondImageTaken = false;

	let createStoryForm: HTMLFormElement;

	let stream: MediaStream | null = null;
	let mediaRecorder: MediaRecorder | null = null;
	let recordedChunks: Blob[] = [];
	let recording = false;
	let recorded = false;
	let videoBlob: File | Blob;
	let videoUrl: string | null = null;

	let imageFiles: File[] = [];
	$: submitting = false;

	onMount(async () => {
		const loader = new Loader({
			apiKey,
			version: 'weekly',
		});

		await loader.load();

		map = new google.maps.Map(mapContainer, {
			center: { lat: 38.736946, lng: -9.142685 }, // Lisbon
			zoom: 15,
			mapTypeControl: false,
			streetViewControl: false,
		});

		map.addListener('click', (e) => {
			const lat = e.latLng.lat();
			const lng = e.latLng.lng();
			$formData.lat = lat;
			$formData.lng = lng;

			if (marker) {
				marker.setPosition({ lat, lng });

			} else {
				marker = new google.maps.Marker({
					position: { lat, lng },
					map,
				});
			}
		});
	});

	function handleMediaUpload(event: Event) {
		if (event.target){
			const target = event.target as HTMLInputElement;
			if(target.files){
				videoBlob = target.files[0];
				videoUrl = URL.createObjectURL(videoBlob);
				recorded = true;
				console.log('video', videoBlob);
			}
		}
	}

	function handleImageUpload(event: Event) {
		if (event.target){
			const target = event.target as HTMLInputElement;
			if(target.files){
				imageFiles.push(...target.files);
				console.log('images', imageFiles);
				if (!firstImageTaken) {
					firstImageTaken = true;
				} else if (!secondImageTaken) {
					secondImageTaken = true;
				}
			}
		}
	}

	const upload = (type: string) => {
		recordingType = type;
		const id = type === 'video' ? 'videoFile' : 'audioFile';
		document.getElementById(id)!.click();
	};

	async function startRecording() {
		try {
			stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });

			mediaRecorder = new MediaRecorder(stream);
			recordedChunks = [];

			mediaRecorder.ondataavailable = (e) => {
				if (e.data.size > 0) {
				recordedChunks.push(e.data);
			}
		};

		mediaRecorder.onstop = async () => {
			videoBlob = new Blob(recordedChunks, { type: 'video' });
			videoUrl = URL.createObjectURL(videoBlob);
			recorded = true;
		};

		mediaRecorder.start();
		recording = true;
		} catch (err) {
			console.error('Camera access error:', err);
		}
	}

	function stopRecording() {
		if (mediaRecorder && recording) {
			mediaRecorder.stop();

			if(stream){
				stream.getTracks().forEach(track => track.stop());
				recording = false;
			}
		}
	}

	function deleteRecording(){
		videoBlob = new Blob();
		recorded = false;
		recording = false;
		videoUrl = null;
		const id = recordingType === 'video' ? 'videoFile' : 'audioFile';
		(document.getElementById(id) as HTMLInputElement).value = '';
	}

	async function uploadVideo(video: File | Blob, type: string) {
		const tempFormData = new FormData();
		tempFormData.append('file', video);
		tempFormData.append('upload_preset', 'curraleira');

		// Make the request to Cloudinary's upload endpoint
		try {
			const response = await fetch(
			`https://api.cloudinary.com/v1_1/${PUBLIC_CLOUDINARY_CLOUD_NAME}/${type}/upload`,
				{
					method: 'POST',
					body: tempFormData,
				}
			);

			const data = await response.json();

			return data.secure_url;

		} catch (error) {
			console.error('Error uploading the video:', error);
			return null;
		}
	}

	async function submitCreateStoryForm(event: Event) {
		submitting = true;
		event.preventDefault();

		const form = event.currentTarget as HTMLFormElement;

		const formData = new FormData(form);

		const cloudUrl = await uploadVideo(videoBlob, 'video');

		if (!cloudUrl) {
			console.error('Failed to upload video');
			return;
		}

		const urls = [];

		for (const image of imageFiles) {
			const url = await uploadVideo(image, 'image');
			urls.push(url);
		}

		// formData to send to server

		let newFormData = new FormData();

		// Iterate over the entries of the original FormData
		for (let [key, value] of formData.entries()) {
			if (key !== 'image' && key !== 'recording_link') {
				newFormData.append(key, value);
			}
		}

		const mp4Url = cloudUrl.replace('/upload/', '/upload/f_mp4/')

		newFormData.append('recording_link', mp4Url);
		urls.forEach((url) => newFormData.append('image', url));

		const response = await fetch('?/createStory', {
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
		action="?/createStory"
		bind:this={createStoryForm}
		on:submit|preventDefault={submitCreateStoryForm}
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
					<span class="inline-block flex justify-center gap-2 pt-3">
						<Input class="w-auto" {...attrs} bind:value={$formData.storyteller} required />
						<Form.FieldErrors />
						<span
							><Button class="p-2" type="button" on:click={() => (page = 2)}><ArrowRight /></Button
							></span
						>
					</span>
				</Form.Control>
			</Form.Field>
		</div>
		<div class="page" class:show={page === 2}>
			<img class="mx-auto" src="/app_images/taking_notes.png" alt={altImg} width={280} />
			<Form.Field {form} name="tags" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-3xl font-semibold tracking-tight transition-colors"
						>Se existe, qual é o local em que esta entrevista se foca? </Form.Label
					>
					<span class="inline-block flex justify-center gap-2 pt-3">
						<Input class="w-auto" {...attrs} bind:value={$formData.tags[1]} />
						<Form.FieldErrors />
						<span
							><Button class="p-2" type="button" on:click={() => (page = 3)}><ArrowRight /></Button
							></span
						>
					</span>
				</Form.Control>
			</Form.Field>
			<Form.Field {form} hidden name="role" class="text-center">
				<Form.Control let:attrs>
					<input hidden name="role" bind:value={$formData.role} />
					<Form.FieldErrors />
				</Form.Control>
			</Form.Field>
			<Form.Field {form} hidden name="tags" class="text-center">
				<Form.Control let:attrs>
					<input hidden name="tags" bind:value={$formData.tags[0]} />
					<Form.FieldErrors />
				</Form.Control>
			</Form.Field>
		</div>

		<div class="page" class:show={page === 3}>
			<img class="mx-auto" src="/app_images/taking_notes.png" alt={altImg} width={280} />
			<Form.Field {form} name="tags" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-3xl font-semibold tracking-tight transition-colors"
						>Se existe, em que período é que esta entrevista se foca?</Form.Label
					>
					<span class="inline-block flex justify-center gap-2 pt-3">
						<Input class="w-auto" {...attrs} bind:value={$formData.tags[2]} />
						<Form.FieldErrors />
						<span
							><Button class="p-2" type="button" on:click={() => (page = 4)}><ArrowRight /></Button
							></span
						>
					</span>
				</Form.Control>
			</Form.Field>
		</div>

		<div class="page" class:show={page === 4}>
			<h2 class="pb-4 text-center text-3xl font-semibold">
				A história está relacionada com um local específico? Se sim, escolhe esse local no mapa.
			</h2>

			<div bind:this={mapContainer} class="h-[600px] w-full max-w-2xl mx-auto rounded shadow-lg"></div>

			<input type="hidden" name="lat" value={$formData.lat ?? ''} />
			<input type="hidden" name="lng" value={$formData.lng ?? ''} />

			<div class="flex justify-center pt-6">
				<Button on:click={() => (page = 5)}>
					<ArrowRight class="mr-2 h-4 w-4" />
					Continuar
				</Button>
			</div>
		</div>

		<div class="page" class:show={page === 5}>
			<Form.Field hidden {form} name="recording_link" class="text-center">
				<Form.Control let:attrs>
					<div class="flex flex-col items-center gap-2">
						<input
							type="file"
							accept="video/*"
							id="videoFile"
							on:change={handleMediaUpload}
							class="hidden"
						/>
					</div>
				</Form.Control>
			</Form.Field>

			<Form.Field hidden {form} name="recording_link" class="text-center">
				<Form.Control let:attrs>
					<div class="flex flex-col items-center gap-2">
						<input
							type="file"
							accept="audio/*"
							id="audioFile"
							on:change={handleMediaUpload}
							class="hidden"
						/>
					</div>
				</Form.Control>
			</Form.Field>

			<div class="mx-auto mt-6 h-[150px] w-[280px] px-4">
				<Carousel.Root>
					<Carousel.Content>
						{#each questions as question}
							<Carousel.Item class="w-full">
								<div class="p-2 text-center">
									<span class="text-sm font-semibold">{question}</span>
								</div>
							</Carousel.Item>
						{/each}
					</Carousel.Content>
					<Carousel.Previous />
					<Carousel.Next />
				</Carousel.Root>
			</div>
			<div class="flex justify-center mt-4">
				{#if videoUrl && !recording}
					<video src={videoUrl} controls class="rounded shadow-lg w-[640px] max-w-full"></video>
				{/if}
			</div>
			<div class="mt-4 text-center">
				<div class="flex flex-col items-center gap-2">
					<div class="flex items-center gap-2">
						{#if !recording && !recorded}
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white"
								on:click={() => startRecording()}
							>
							Start Recording
							</Button>
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white"
								on:click={() => upload('video')}
							>
								<Video />
							</Button>
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white"
								on:click={() => upload('audio')}
							>
								<Mic />
							</Button>
						{:else if recording && !recorded}
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white"
								on:click={() => stopRecording()}
							>
							Stop Recording
							</Button>
						{:else if recorded && !recording} 
							<Button
								type="button"
								class="cursor-pointer bg-red-500 p-2 text-sm text-white"
								on:click={() => deleteRecording()}
							>
							Refazer gravação
							</Button>
						{/if}
						<Button
							class="p-2"
							on:click={() => (page = 6)}
							disabled={recorded === false}
						>
							<ArrowRight />
						</Button>
					</div>
				</div>
			</div>
		</div>
		<div class="page" class:show={page === 6}>
			<img class="mx-auto" src="/app_images/taking_notes.png" alt={altImg} width={280} />
			<Form.Field {form} name="image" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-3xl font-semibold tracking-tight transition-colors"
						>Tire duas fotografias da pessoa.</Form.Label
					>
					<div class="flex flex-col items-center gap-2">
						<input
							type="file"
							accept="image/*"
							id="firstImageFile"
							capture="environment"
							on:change={handleImageUpload}
							class="hidden"
						/>
						<input
							type="file"
							accept="image/*"
							id="secondImageFile"
							capture="environment"
							on:change={handleImageUpload}
							class="hidden"
						/>
						<div class="flex items-center gap-2">
							{#if !firstImageTaken}
								<Button
									type="button"
									class="cursor-pointer bg-black p-2 text-sm text-white"
									on:click={() => triggerFileInput('firstImageFile')}
								>
									<Camera class="mr-2 h-4 w-4" />
									Tirar Primeira Fotografia
								</Button>
							{:else if !secondImageTaken}
								<Button
									type="button"
									class="cursor-pointer bg-black p-2 text-sm text-white"
									on:click={() => triggerFileInput('secondImageFile')}
								>
									<Camera class="mr-2 h-4 w-4" />
									Tirar Segunda Fotografia
								</Button>
							{/if}
						</div>
						{#if imageFiles.length > 1}
							<Check class="h-4 w-4 text-green-600" />
							<p class="text-green-600">Fotografias guardadas</p>
						{/if}
					</div>
				</Form.Control>
			</Form.Field>

			<div class="mt-28 text-center">
				<Button type="submit" disabled={submitting}>
					{#if submitting}
						<Loader2 class="mr-2 h-4 w-4 animate-spin" />
					{/if}
					Guardar História
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
</style>
