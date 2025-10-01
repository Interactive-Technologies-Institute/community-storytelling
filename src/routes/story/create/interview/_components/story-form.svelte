<script lang="ts">
	import { applyAction, deserialize } from '$app/forms';
	import { PUBLIC_CLOUDINARY_CLOUD_NAME} from '$env/static/public';
	import { Button } from '$lib/components/ui/button';
	import * as Carousel from '$lib/components/ui/carousel/index.js';
	import * as Form from '$lib/components/ui/form';
	import { createStorySchema, type CreateStorySchema } from '$lib/schemas/story';

	import { superForm, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient, type Infer } from 'sveltekit-superforms/adapters';

	import Input from '$lib/components/ui/input/input.svelte';
	import { onMount, tick } from 'svelte';

	import { ArrowLeft, ArrowRight, ArrowUp, Camera, Check, Loader2, Mic, Video } from 'lucide-svelte';

	import Map from '../../../../map/_components/map.svelte';
	import Marker from '../../../../map/_components/marker.svelte';
	
	let mapCenter = { lat: 38.7382, lng: -9.1212 };
	let markerPosition: { lat: number; lng: number } | null = null;

	const questions = [
		'Pode apresentar-se e falar um pouco sobre si? Que atividades ou funções exerce atualmente no bairro?',
		'Que memórias ou histórias marcantes possui do bairro? De que forma já esteve envolvido(a) com a comunidade no passado (trabalho, projetos ou atividades)?',
		'Na sua perspetiva, que mudanças mais importantes aconteceram no bairro ao longo dos anos?',
		'Como é que as suas atividades e o seu papel no bairro influenciam a sua vida pessoal e a comunidade em geral?',
		'Quais são os seus sonhos ou expectativas para o bairro nos próximos anos? De que forma gostaria de contribuir para o futuro do bairro através do seu papel?',
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
	$formData.tags[0] = 'Entrevista';
	$formData.pinColor = $formData.pinColor ?? '#ff0000';

	let recordingType = '';

	let createStoryForm: HTMLFormElement;

	let stream: MediaStream | null = null;
	let mediaRecorder: MediaRecorder | null = null;
	let recordedChunks: Blob[] = [];
	let recording = false;
	let recorded = false;
	let videoBlob: File | Blob;
	let videoUrl: string | null = null;
	let videoElement: HTMLVideoElement;

	let firstImageTaken = false;
	let secondImageTaken = false;
	let imageFiles: File[] = [];
	let photoStream: MediaStream | null = null;
	let photoVideoEl: HTMLVideoElement;
	let takingPhoto = false;
	let retakeMode = false;
	const isMobile = /Mobi|Android/i.test(navigator.userAgent);
	let currentCamera: 'user' | 'environment' = isMobile ? 'environment' : 'user';

	$: submitting = false;

	let currentCaptureSlot: 'first' | 'second' | null = null;

	let search = '';
	let results: { id: string; display_name: string }[] = [];
	let selectedMembers: { id: string; display_name: string }[] = [];

	$: results = search.trim()
		? (data.data.extra?.users ?? []).filter(u =>
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

	function handleMapClick(event: CustomEvent<{ lat: number; lng: number }>) {
		markerPosition = event.detail;
		$formData.lat = event.detail.lat;
		$formData.lng = event.detail.lng;
	}

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
		const target = event.target as HTMLInputElement;
		if (target.files && target.files.length > 0) {
			const file = target.files[0];
			if (target.id === 'firstImageFile') {
				imageFiles[0] = file;
				firstImageTaken = true;
			} else if (target.id === 'secondImageFile') {
				imageFiles[1] = file;
				secondImageTaken = true;
			}
			retakeMode = false;
		}
	}

	const upload = (type: string) => {
		recordingType = type;
		const id = type === 'video' ? 'videoFile' : 'audioFile';
		document.getElementById(id)!.click();
	};

	async function startPhotoCapture(slot: 'first' | 'second') {
		try {
			photoStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: isMobile ? 'environment' : 'user' } });
			takingPhoto = true;
			retakeMode = false;
			currentCaptureSlot = slot;
			await tick();
			photoVideoEl.srcObject = photoStream;
			await photoVideoEl.play();
		} catch (error) {
			console.error('Camera access denied:', error);
		}
	}
	function capturePhoto() {
		const canvas = document.createElement('canvas');
		canvas.width = photoVideoEl.videoWidth;
		canvas.height = photoVideoEl.videoHeight;

		const ctx = canvas.getContext('2d');
		if (ctx) {
			ctx.drawImage(photoVideoEl, 0, 0, canvas.width, canvas.height);
			canvas.toBlob((blob) => {
				if (blob) {
					const file = new File([blob], `photo_${Date.now()}.jpg`, { type: 'image/jpeg' });

					if (!firstImageTaken) {
						imageFiles[0] = file;
						firstImageTaken = true;
					} else if (!secondImageTaken) {
						imageFiles[1] = file;
						secondImageTaken = true;
					}
					retakeMode = true;
					stopPhotoCapture();
				}
			}, 'image/jpeg');
		}
	}

	function stopPhotoCapture() {
		if (photoStream) {
			photoStream.getTracks().forEach((track) => track.stop());
			takingPhoto = false;
		}
	}

	function retakePhoto() {
		retakeMode = false;
		if (currentCaptureSlot) {
			startPhotoCapture(currentCaptureSlot);
		}
	}

	function confirmPhoto() {
		retakeMode = false;
		currentCaptureSlot = null;
	}

	async function startRecording(type: string) {
		try {
			if(type === 'video'){
				stream = await navigator.mediaDevices.getUserMedia({
					video: { facingMode: isMobile ? 'environment' : 'user' },
					audio: true
				});
				recording = true;
				recordingType = 'video';
				
				await tick();
				if (videoElement) {
					videoElement.srcObject = stream;
					await videoElement.play();
				}
			}

			else{
				stream = await navigator.mediaDevices.getUserMedia({ audio: true });
				recordingType = 'audio';
				recording = true;
			}

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
			recording = false;
		};

		mediaRecorder.start();

		} catch (err) {
			console.error('Camera and/or audio access error:', err);
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

	function resetPhotos() {
		imageFiles = [];
		firstImageTaken = false;
		secondImageTaken = false;

		
		const firstInput = document.getElementById('firstImageFile') as HTMLInputElement;
		const secondInput = document.getElementById('secondImageFile') as HTMLInputElement;

		if (firstInput) firstInput.value = '';
		if (secondInput) secondInput.value = '';
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

		$formData.tags = [
			$formData.year?.toString() ?? '0',
			$formData.tags[0]
		]

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
			if (key !== 'image' && key !== 'recording_link' && key !== 'coauthors' && key !== 'tags') {
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

<div class="container mx-auto space-y-10 pb-10 px-4 sm:px-6">
	<form
		method="POST"
		action="?/createStory"
		bind:this={createStoryForm}
		on:submit|preventDefault={submitCreateStoryForm}
		enctype="multipart/form-data"
		class="flex flex-col gap-y-10"
	>
		<div class="page" class:show={page === 1}>
			<Form.Field hidden {form} name="recording_link" class="text-center">
				<Form.Control let:attrs>
					<input type="file" accept="video/*" id="videoFile" on:change={handleMediaUpload} class="hidden" />
				</Form.Control>
			</Form.Field>

			<Form.Field hidden {form} name="recording_link" class="text-center">
				<Form.Control let:attrs>
					<input type="file" accept="audio/*" id="audioFile" on:change={handleMediaUpload} class="hidden" />
				</Form.Control>
			</Form.Field>

			<div class="mx-auto mt-6 h-[150px] w-full max-w-xs sm:max-w-sm md:max-w-md px-4">
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
				<!-- svelte-ignore a11y-media-has-caption -->
				{#if videoUrl && !recording}
					<video src={videoUrl} controls class="rounded shadow-lg w-full max-w-2xl"></video>
				{/if}
			</div>

			<div class="mt-4 text-center">
				<div class="flex flex-col items-center gap-2">
					{#if recording && recordingType === 'video'}
						<video
							bind:this={videoElement}
							autoplay
							muted
							playsinline
							class="rounded border border-gray-300 w-full max-w-md md:w-[640px] md:h-[480px]"
						></video>
					{/if}

					<div class="flex flex-wrap justify-center gap-2 mt-2">
						{#if !recording && !recorded}
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white flex-1 min-w-[120px]"
								on:click={() => startRecording('video')}
							>
								<Video />
								<span>Gravar Vídeo</span>
							</Button>
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white flex-1 min-w-[120px]"
								on:click={() => startRecording('audio')}
							>
								<Mic />
								<span>Gravar Áudio</span>
							</Button>
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white flex-1 min-w-[120px]"
								on:click={() => upload('video')}
							>
								<ArrowUp />
								<span>Upload Vídeo</span>
							</Button>
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white flex-1 min-w-[120px]"
								on:click={() => upload('audio')}
							>
								<ArrowUp />
								<span>Upload Áudio</span>
							</Button>
						{:else if recording && !recorded}
							<Button
								type="button"
								class="cursor-pointer bg-black p-2 text-sm text-white flex-1 min-w-[120px]"
								on:click={() => stopRecording()}
							>
								Stop Recording
							</Button>
						{:else if recorded && !recording}
							<Button
								type="button"
								class="cursor-pointer bg-red-500 p-2 text-sm text-white flex-1 min-w-[120px]"
								on:click={() => deleteRecording()}
							>
								Refazer gravação
							</Button>
						{/if}

						<Button
							class="px-6 py-2 bg-green-600 text-white hover:bg-green-700 w-full sm:w-auto flex items-center justify-center gap-2"
							on:click={() => (page = 2)}
							disabled={!recorded}
						>
							<ArrowRight />
						</Button>
					</div>
				</div>
			</div>
		</div>

		<div class="page" class:show={page === 2}>
			<img class="mx-auto w-40 sm:w-56 md:w-72" src="/app_images/taking_notes.png" alt={altImg} />
			<Form.Field {form} name="storyteller" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-2xl sm:text-3xl font-semibold tracking-tight">
						Qual é o nome da pessoa a ser entrevistada?
					</Form.Label>
					<div class="flex flex-col items-center gap-3 pt-3 w-full">
						<Input class="w-full max-w-sm" {...attrs} bind:value={$formData.storyteller}
							on:blur={() => form.validate('storyteller')}
							on:input={() => form.validate('storyteller')} />
						<Form.FieldErrors />
						<Button class="px-6 py-2 bg-green-600 text-white hover:bg-green-700 w-full sm:w-auto flex items-center justify-center gap-2"
							type="button" on:click={() => (page = 3)}
							disabled={$formData.storyteller.length < 2 || $formData.storyteller.length > 100}>
							<ArrowRight />
						</Button>
					</div>
				</Form.Control>
			</Form.Field>
		</div>

		<div class="page" class:show={page === 3}>
			<h2 class="pb-2 text-3xl font-semibold tracking-tight text-center">
				Quem desenvolveu esta história contigo?
			</h2>

			<input
				type="text"
				placeholder="Procura por membros..."
				bind:value={search}
				class="block w-full max-w-md mx-auto p-2 border rounded mt-4"
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
					class="px-6 py-2 bg-green-600 text-white hover:bg-green-700 w-full sm:w-auto flex items-center justify-center gap-2"
					on:click={() => (page = 4)}
				>
					<ArrowRight />
				</Button>
			</div>
		</div>

		<div class="page" class:show={page === 4}>
			<img class="mx-auto w-40 sm:w-56 md:w-72" src="/app_images/taking_notes.png" alt={altImg} />
			<Form.Field {form} name="year" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-2xl sm:text-3xl font-semibold tracking-tight">
						Se existe, em que período é que esta história se foca?
					</Form.Label>
					<div class="flex flex-col items-center gap-3 pt-3 w-full">
						<Input class="w-full max-w-xs" {...attrs} bind:value={$formData.year}
							on:blur={() => form.validate('year')}
							on:input={() => form.validate('year')} />
						<Form.FieldErrors />
						<Button class="px-6 py-2 bg-green-600 text-white hover:bg-green-700 w-full sm:w-auto flex items-center justify-center gap-2"
							type="button" on:click={() => (page = 5)}
							disabled={$formData.year !== '' && $formData.year !== undefined &&
								(isNaN(Number($formData.year)) || Number($formData.year) < 1950 || Number($formData.year) > 2030)}>
							<ArrowRight />
						</Button>
					</div>
				</Form.Control>
			</Form.Field>
		</div>

		<div class="page" class:show={page === 5}>
			<h2 class="pb-4 text-2xl sm:text-3xl font-semibold text-center">
				A história está relacionada com um local específico? Se sim, escolhe esse local no mapa.
			</h2>

			<div class="h-[400px] sm:h-[500px] md:h-[600px] w-full max-w-2xl mx-auto rounded shadow-lg">
				<Map lng={mapCenter.lng} lat={mapCenter.lat} zoom={14} on:mapClick={handleMapClick}>
					{#if markerPosition}
						<Marker lng={markerPosition.lng} lat={markerPosition.lat} disableClick={true} marker_color={$formData.pinColor} />
					{/if}
				</Map>
			</div>

			<div class="mt-4 flex flex-col items-center gap-2">
				<label for="pinColor" class="text-lg font-medium">Escolhe a cor do marcador:</label>
				<input type="color" id="pinColor" bind:value={$formData.pinColor} class="w-12 h-12 rounded-full border p-0" />
			</div>

			<input type="hidden" name="pinColor" value={$formData.pinColor} />
			<input type="hidden" name="lat" value={$formData.lat ?? ''} />
			<input type="hidden" name="lng" value={$formData.lng ?? ''} />

			<div class="flex justify-center pt-6">
				<Button class="px-6 py-2 bg-green-600 text-white hover:bg-green-700 w-full sm:w-auto flex items-center justify-center gap-2"
					on:click={() => (page = 6)} disabled={recorded === false}>
					<ArrowRight />
				</Button>
			</div>
		</div>

		<div class="page" class:show={page === 6}>
			<img class="mx-auto w-40 sm:w-56 md:w-72" src="/app_images/taking_notes.png" alt={altImg} />
			<Form.Field {form} name="image" class="text-center">
				<Form.Control let:attrs>
					<Form.Label class="pb-2 text-2xl sm:text-3xl font-semibold tracking-tight">
						Submete duas fotografias da pessoa.
					</Form.Label>
					<div class="flex flex-col gap-4 items-center">
						<div class="flex flex-col sm:flex-row gap-2 justify-center">
							{#if !firstImageTaken}
								<Button type="button" class="cursor-pointer bg-black p-2 text-sm text-white flex items-center"
									on:click={() => triggerFileInput('firstImageFile')}>
									<ArrowUp /><span>Upload Primeira Fotografia</span>
								</Button>
								<Button type="button" class="cursor-pointer bg-black p-2 text-sm text-white flex items-center"
									on:click={() => startPhotoCapture('first')}>
									<Camera class="mr-2 h-4 w-4" /><span>Tirar Primeira Fotografia</span>
								</Button>
							{:else if !secondImageTaken}
								<Button type="button" class="cursor-pointer bg-black p-2 text-sm text-white flex items-center"
									on:click={() => triggerFileInput('secondImageFile')}>
									<ArrowUp /><span>Upload Segunda Fotografia</span>
								</Button>
								<Button type="button" class="cursor-pointer bg-black p-2 text-sm text-white flex items-center"
									on:click={() => startPhotoCapture('second')}>
									<Camera class="mr-2 h-4 w-4" /><span>Tirar Segunda Fotografia</span>
								</Button>
							{/if}
						</div>

						<input id="firstImageFile" type="file" accept="image/*" on:change={handleImageUpload} class="hidden" />
						<input id="secondImageFile" type="file" accept="image/*" on:change={handleImageUpload} class="hidden" />

						{#if imageFiles.length > 0}
							<div class="flex items-center gap-2 text-sm text-green-600">
								<Check class="h-4 w-4" />
								<p>Fotografias guardadas ({imageFiles.length})</p>
							</div>
						{/if}

						<!-- svelte-ignore a11y-media-has-caption -->
						{#if takingPhoto}
							<video bind:this={photoVideoEl} autoplay playsinline class="w-full max-w-md rounded-lg" />
							<div class="mt-2 flex flex-wrap gap-2 justify-center">
								<Button on:click={capturePhoto} class="bg-green-600 text-white p-2">Capturar Foto</Button>
								<Button on:click={stopPhotoCapture} class="bg-red-500 text-white p-2">Cancelar</Button>
							</div>
						{/if}

						{#if retakeMode}
							<img src={URL.createObjectURL(currentCaptureSlot === 'first' ? imageFiles[0] : imageFiles[1])}
								alt="Foto capturada" class="w-full max-w-md rounded-lg mt-4" />
							<div class="flex gap-2 justify-center mt-2">
								<Button on:click={confirmPhoto} class="bg-green-600 text-white p-2">Confirmar</Button>
								<Button on:click={retakePhoto} class="bg-yellow-500 text-white p-2">Refazer</Button>
							</div>
						{/if}
					</div>
				</Form.Control>
			</Form.Field>

			<div class="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
				{#if secondImageTaken}
					<Button type="button" variant="destructive" on:click={resetPhotos} class="w-full sm:w-auto">
						Apagar Fotografias
					</Button>
				{/if}
				<Button type="submit" disabled={!secondImageTaken} class="w-full sm:w-auto">
					{#if submitting}
						<Loader2 class="mr-2 h-4 w-4 animate-spin" />
					{/if}
					Guardar História
				</Button>
			</div>
		</div>
	</form>

	{#if page !== 1}
		<div class="sticky bottom-0 flex w-full flex-col items-center justify-center gap-y-4 border-t bg-background/95 py-4 backdrop-blur supports-[backdrop-filter]:bg-background/60 sm:flex-row sm:gap-x-10 sm:py-8 px-4">
			<Button variant="outline" on:click={() => (page > 1 ? (page = page - 1) : page)} class="w-full sm:w-auto">
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
