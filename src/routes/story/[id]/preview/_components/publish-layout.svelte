<script lang="ts">
	import { PUBLIC_CLOUDINARY_CLOUD_NAME, PUBLIC_OPENAI_API_KEY } from '$env/static/public';
	import { Button } from '$lib/components/ui/button';
	import * as Carousel from '$lib/components/ui/carousel/index.js';
	import { type CarouselAPI } from '$lib/components/ui/carousel/context.js';
	import * as Card from '$lib/components/ui/card/index.js';

	import * as Tabs from '$lib/components/ui/tabs/index.js';

	import { PencilLine } from 'lucide-svelte';

	import InPlaceEdit from './in-place-edit.svelte';
	import PageHeader from '@/components/page-header.svelte';
	import { previewStorySchema, type PreviewStorySchema } from '@/schemas/preview_story';
	import { onMount } from 'svelte';
	import { superForm, type Infer, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient } from 'sveltekit-superforms/adapters';
	import OpenAI from 'openai';
	import { applyAction, deserialize } from '$app/forms';
	import { Loader2 } from 'lucide-svelte';

	export let data: SuperValidated<Infer<PreviewStorySchema>>;
	export let user;

	const form = superForm(data, {
		validators: zodClient(previewStorySchema),
		taintedMessage: true,
		dataType: 'json',
		resetForm: false,
	});

	const { form: formData, enhance } = form;

	let updateStoryForm: HTMLFormElement;
	let title: string;
	let paragraphs: string[] = [];
	let quotes: string[] = [];
	let user_id = '';
	let currentTab = 't1';

	const openai = new OpenAI({ apiKey: PUBLIC_OPENAI_API_KEY, dangerouslyAllowBrowser: true });
	$: transcription = '';

	let interview_text = `
    Eu tenho uma transcrição de uma entrevista sobre o tema (X). O entrevistador fez perguntas para explorar passado, presente e futuro, seguindo este modelo como base:  

	1. "Pode apresentar-se e falar um pouco sobre si? Que atividades ou funções exerce atualmente no bairro?"  
	2. "Que memórias ou histórias marcantes possui do bairro? De que forma já esteve envolvido(a) com a comunidade no passado (trabalho, projetos ou atividades)?"  
	3. "Na sua perspetiva, que mudanças mais importantes aconteceram no bairro ao longo dos anos?"  
	4. "Como é que as suas atividades e o seu papel no bairro influenciam a sua vida pessoal e a comunidade em geral?"  
	5. "Quais são os seus sonhos ou expectativas para o bairro nos próximos anos? De que forma gostaria de contribuir para o futuro do bairro através do seu papel?"  

	A partir da transcrição, em Português de Portugal:  
	- Crie a história da entrevista de uma perspectiva externa.  
	- Inclua citações do entrevistado e do entrevistador, sem inventar informações.  
	- Estruture a narrativa em 5 parágrafos, seguindo:  
	- **Exposição** - personagens, cenário e ambiente.  
	- **Conflito** - problema central.  
	- **Ação ascendente** - acontecimentos que levam ao clímax.  
	- **Clímax** - ponto alto da história.  
	- **Resolução** - conclusão que conecte emocionalmente com o leitor.  

	Depois, crie uma secção "Quotes Importantes" com 2 citações que destaquem o tema da entrevista.  

	Por fim, sugira um "título" para a história.  

	Formato de saída:  

	# História:
	<história criada>
	# Quotes importantes:
	<quotes importantes criados>
	# Título:
	<título criado>
    `;

	let monologue_text = `
    Eu tenho uma transcrição de um monólogo sobre o tema (X). A pessoa fala sobre um local relacionado ao tema, seguindo este modelo:  

	1. "Apresentação: Fale para a câmera sobre quem você é e por que este lugar é importante para você."  
	2. "Recorda o passado: Simbolismo / História deste local, qual é a importância do mesmo."  
	3. "Mudanças ao Longo do Tempo: Como o lugar mudou, seja fisicamente, socialmente ou na forma como as pessoas o utilizam."  
	4. "Experiência Atual: Como as pessoas observam e falam sobre este local."  
	5. "Conclusão: Opinião sobre o futuro, focando em como este local será representado nos próximos anos."  

	A partir da transcrição, em Português de Portugal:  
	- Crie a história do monólogo de uma perspectiva externa.  
	- Inclua citações do orador, sem inventar informações.  
	- Estruture a narrativa em 5 parágrafos, seguindo:  
	- **Exposição** - personagens, cenário e ambiente.  
	- **Conflito** - problema central.  
	- **Ação ascendente** - acontecimentos que levam ao clímax.  
	- **Clímax** - ponto alto da história.  
	- **Resolução** - conclusão que conecte emocionalmente com o leitor.  

	Depois, crie uma secção "Quotes Importantes" com 2 citações que destaquem o tema do monólogo.  

	Por fim, sugira um "título" para a história.  

	Formato de saída:  

	# História:
	<história criada>
	# Quotes importantes:
	<quotes importantes criados>
	# Título:
	<título criado>
    `;

	$: submittingSave = false;
	$: submittingPublish = false;
	let apiImage : CarouselAPI;
	let apiQuote: CarouselAPI;
	let currentFirstImage = 0;
	let currentQuote = 0;
	let selectedImage = '';
	let selectedQuote = '';

	let imageOptions = [
		{ src: $formData.image[0], alt: 'First Image' },
		{ src: $formData.image[1], alt: 'Second Image' },
	];

	$: if (apiImage) {
		selectedImage = imageOptions[currentFirstImage].src;
		apiImage.on('select', () => {
			currentFirstImage = currentFirstImage === 0 ? 1 : 0;
			selectedImage = imageOptions[currentFirstImage].src;
		});
	}

	$: if (apiQuote) {
		selectedQuote = quotes[currentQuote];
		apiQuote.on('select', () => {
			currentQuote = currentQuote === 0 ? 1 : 0;
			selectedQuote = quotes[currentQuote];
		});
	}

	async function organizeText(text: string): Promise<[string[], string[], string]> {
		let paragraphsText: string[] = [];
		let quotesText: string[] = [];
		let titleText: string = '';

		// Separate the story from the quotes
		let parts = text.split('# Quotes importantes:');

		// Split the story into paragraphs and trim any extra whitespace
		if (parts[0]) {
			paragraphsText = parts[0].replace('# História:', '').trim().split('\n\n');
		}

		// Extract quotes from the second part, if it exists
		if (parts[1]) {
			// Split quotes and title (if present)
			let [quotesPart, titlePart] = parts[1].split('# Título:');

			// Process quotes
			if (quotesPart) {
				quotesText = quotesPart
					.trim()
					.split('\n')
					.map((line) =>
						line
							.replace(/^\d+\.\s*/, '')
							.replace(/^"|"$/g, '')
							.trim()
					)
					.filter((line) => line.length > 0);
			}

			if (titlePart) {
				titleText = titlePart.trim();
			}
		}

		console.log(paragraphsText);
		console.log(quotesText);
		console.log(titleText);

		return [paragraphsText, quotesText, titleText];
	}

	async function transcribe(audioFile: File) {
		try {
			const transcription = await openai.audio.transcriptions.create({
				file: audioFile,
				model: 'whisper-1',
				response_format: 'text',
			});

			return transcription;
		} catch (error) {
			console.log('error in transcription', error);
			return null;
		}
	}

	async function generate_story(role: string, transcription: string) {
		try {
			const response = await openai.chat.completions.create({
				model: 'gpt-4o',
				messages: [
					{
						role: 'system',
						content: role === 'interview' ? `${interview_text}` : `${monologue_text}`,
					},
					{
						role: 'user',
						content: transcription,
					},
				],
				temperature: 1,
				max_tokens: 1600,
				top_p: 1,
			});

			console.log(response);

			return response;
		} catch (error) {
			console.log('error in generating story', error);
			return null;
		}
	}

	const getIdentifier = (url: string) => {
		const regex = /\/([^/]+)\.(mov|mp3|mp4|3gp|avi|mkv|flv|wmv|wav|ogg|aac)$/i;
		const match = url.match(regex);
		return match ? match[1] : null;
	};

	const getExtension = (url: string) => {
		const match = url.match(/\.([0-9a-z]+)(?:[\?#]|$)/i);
		return match ? match[1] : null;
	};

	const getBlobFromUrl = async (url: string) => {
		const response = await fetch(url);
		const arrayBuffer = await response.arrayBuffer();
		const contentType = response.headers.get('content-type') || 'application/octet-stream';
		const blob = new Blob([arrayBuffer], { type: contentType });
		return blob;
	};

	onMount(async () => {
		const formData = $formData;

		user_id = formData.user_id;

		const transcribeRecording = async (recordingLink: string) => {
			const extension = getExtension(recordingLink);
			let videoUrl = recordingLink;

			if (extension !== 'mp4') {
				const identifier = getIdentifier(recordingLink);
				videoUrl = `https://res.cloudinary.com/${PUBLIC_CLOUDINARY_CLOUD_NAME}/video/upload/f_mp4/${identifier}.mp4`;
			}

			try {
				const blob = await getBlobFromUrl(videoUrl);
				const videoFile = new File([blob], 'audio_file.mp4', { type: 'video/mp4' });

				console.log('Transcribing...');
				return await transcribe(videoFile);
			} catch (error) {
				console.error('Error during transcription:', error);
				throw error;
			}
		};

		if (!formData.transcription) {
			try {
				if (formData.recording_link !== undefined){
					const transcriptionResult = await transcribeRecording(formData.recording_link);
					transcription = transcriptionResult ?? "";
					let storyResult = await generate_story(formData.role, transcription);
					if(storyResult && storyResult.choices[0].message.content){
						let [paragraphsResult, quotesResult, titleResult] = await organizeText(storyResult.choices[0].message.content);				
						paragraphs = paragraphsResult;
						quotes = quotesResult;
						title = titleResult;
					}
				}
			} catch (error) {
				console.error('Failed to transcribe recording:', error);
			}
		} else {
			if (formData.pub_story_text) {
				paragraphs = formData.pub_story_text;
				quotes = formData.pub_quotes;
				if (formData.title){
					title = formData.title;
				}
			} else {
				let storyResult = await generate_story(formData.role, formData.transcription);
				if(storyResult && storyResult.choices[0].message.content){
					let [paragraphsResult, quotesResult, titleResult] = await organizeText(storyResult.choices[0].message.content);				
					paragraphs = paragraphsResult;
					quotes = quotesResult;
					title = titleResult;
				}
			}
		}
	});

	function submit(field: string) {
		return ({ detail: newValue }: CustomEvent<string>) => {
			console.log(`updated ${field}, new value is: "${newValue}"`);
		};
	}

	async function submitUpdateStoryForm(event: SubmitEvent) {
		const submitter = event.submitter as HTMLButtonElement;

		if (submitter && submitter.value === 'save') {
			submittingSave = true;
		} else {
			submittingPublish = true;
		}

		event.preventDefault();

		const form = event.currentTarget as HTMLFormElement;
		
		const newFormData = new FormData(form);

		if (event.submitter) {
			newFormData.append(submitter.name, submitter.value);
		}

		paragraphs.forEach((p) => newFormData.append('pub_story_text', p));
		newFormData.append('pub_quotes', quotes[currentQuote]);
		newFormData.append('pub_quotes', currentQuote == 0 ? quotes[1] : quotes[0]);
		newFormData.append('pub_selected_images', selectedImage);
		newFormData.append('title', title);
		newFormData.append(
			'pub_selected_images',
			currentFirstImage == 0 ? imageOptions[1].src : imageOptions[0].src
		);
		newFormData.append('id', $formData.id.toString());
		newFormData.append('template', currentTab);

		const response = await fetch('?/updateStory', {
			method: 'POST',
			body: newFormData,
			headers: {
				'x-sveltekit-action': 'true',
			},
		});

		const result = deserialize(await response.text());
		if (result.type === 'success') {
			if (submitter.value === 'save') {
				submittingSave = false;
			} else {
				submittingPublish = false;
			}
		}

		applyAction(result);
	}
</script>

<PageHeader title={'Resumo da história'} subtitle="" />
<form method="POST" bind:this={updateStoryForm} on:submit|preventDefault={submitUpdateStoryForm}>
	<div class="container mx-auto space-y-10 pb-10">
		{#if paragraphs.length === 0}
			<PencilLine class="mx-auto h-32 w-32" />
			<h2 class="mb-2 text-center text-2xl font-medium">A gerar a história...</h2>
			<p class="text-center">Por favor, não recarregue a página.</p>
		{:else}
			<Tabs.Root bind:value={currentTab}>
				<Tabs.List class="grid w-full grid-cols-3">
					<Tabs.Trigger value="t1">Modelo 1</Tabs.Trigger>
					<Tabs.Trigger value="t2">Modelo 2</Tabs.Trigger>
					<Tabs.Trigger value="t3">Modelo 3</Tabs.Trigger>
				</Tabs.List>
				<Tabs.Content value="t1">
					<Card.Root>
						<Card.Header>
							<Card.Title>Resumo com Modelo 1</Card.Title>
							<Card.Description>
								Isto é um resumo da sua história. A sua história aparecerá neste formato quando a
								publicar. Pode editá-la clicando no texto. Arraste as imagens e os quotes para o
								lado para escolher o que mostrar.
							</Card.Description>
						</Card.Header>
						<Card.Content class="space-y-2">
							<div class="mb-6 text-center">
								<h2 class="text-5xl font-bold">
									<InPlaceEdit bind:value={title} on:submit={submit('title')} />
								</h2>
							</div>
							<div
								class="auto mb-4 w-auto flex-shrink-0 sm:max-w-sm md:float-left md:max-w-md lg:float-left lg:mb-0 lg:mr-4 lg:max-w-xs"
							>
								<Carousel.Root bind:api={apiImage}>
									<Carousel.Content>
										{#each imageOptions as image, i (i)}
											<Carousel.Item>
												<div class="p-1">
													<Card.Root>
														<Card.Content
															class="flex aspect-square items-center justify-center p-6"
														>
															<img
																src={image.src}
																alt={image.alt}
																class="h-70 w-60 rounded-lg object-cover"
															/>
														</Card.Content>
													</Card.Root>
												</div>
											</Carousel.Item>
										{/each}
									</Carousel.Content>
								</Carousel.Root>
							</div>

							{#each paragraphs as p}
								<p class="text-justify">
									<InPlaceEdit bind:value={p} on:submit={submit('text')} />
								</p>
							{/each}
						</Card.Content>
					</Card.Root>
				</Tabs.Content>
				<Tabs.Content value="t2">
					<Card.Root>
						<Card.Header>
							<Card.Title>Resumo com Modelo 2</Card.Title>
							<Card.Description>
								Isto é um resumo da sua história. A sua história aparecerá neste formato quando a
								publicar. Pode editá-la clicando no texto. Arraste as imagens e os quotes para o
								lado para escolher o que mostrar.
							</Card.Description>
						</Card.Header>
						<Card.Content class="space-y-2">
							<div class="mb-6 text-center">
								<h2 class="text-5xl font-bold">
									<InPlaceEdit bind:value={title} on:submit={submit('title')} />
								</h2>
							</div>
							<div
								class="mb-4 w-full flex-shrink-0 sm:max-w-sm md:float-left md:max-w-md lg:float-left lg:mb-0 lg:mr-4 lg:max-w-xs"
							>
								<Carousel.Root bind:api={apiImage}>
									<Carousel.Content>
										{#each imageOptions as image, i (i)}
											<Carousel.Item>
												<div class="p-1">
													<Card.Root>
														<Card.Content
															class="flex aspect-square items-center justify-center p-6"
														>
															<img
																src={image.src}
																alt={image.alt}
																class="h-auto w-full rounded-lg object-cover"
															/>
														</Card.Content>
													</Card.Root>
												</div>
											</Carousel.Item>
										{/each}
									</Carousel.Content>
								</Carousel.Root>
							</div>

							<div class="justify-right mt-6 flex w-2/3">
								<Carousel.Root bind:api={apiQuote}>
									<Carousel.Content>
										{#each quotes as quote, i (i)}
											<Carousel.Item>
												<blockquote
													class="border-s-4 border-gray-300 bg-gray-50 p-2 text-xl font-medium italic leading-relaxed text-gray-900 dark:border-gray-500 dark:bg-gray-800 dark:text-white"
												>
													<InPlaceEdit bind:value={quote} on:submit={submit('text')} />
												</blockquote>
											</Carousel.Item>
										{/each}
									</Carousel.Content>
								</Carousel.Root>
							</div>

							<div class="pt-4">
								{#each paragraphs as p}
									<p class="pt-2 text-justify">
										<InPlaceEdit bind:value={p} on:submit={submit('text')} />
									</p>
								{/each}
							</div>
						</Card.Content>
					</Card.Root>
				</Tabs.Content>
				<Tabs.Content value="t3">
					<Card.Root>
						<Card.Header>
							<Card.Title>Resumo com Modelo 3</Card.Title>
							<Card.Description>
								Isto é um resumo da sua história. A sua história aparecerá neste formato quando a
								publicar. Pode editá-la clicando no texto. Arraste as imagens e os quotes para o
								lado para escolher o que mostrar.
							</Card.Description>
						</Card.Header>
						<Card.Content class="space-y-2">
							<div class="mb-6 text-center">
								<h2 class="text-5xl font-bold">
									<InPlaceEdit bind:value={title} on:submit={submit('title')} />
								</h2>
							</div>
							<div
								class="mb-4 w-full flex-shrink-0 sm:max-w-sm md:float-left md:max-w-md lg:float-left lg:mb-0 lg:mr-4 lg:max-w-xs"
							>
								<Carousel.Root bind:api={apiImage}>
									<Carousel.Content>
										{#each imageOptions as image, i (i)}
											<Carousel.Item>
												<div class="p-1">
													<Card.Root>
														<Card.Content
															class="flex aspect-square items-center justify-center p-6"
														>
															<img
																src={image.src}
																alt={image.alt}
																class="h-auto w-full rounded-lg object-cover"
															/>
														</Card.Content>
													</Card.Root>
												</div>
											</Carousel.Item>
										{/each}
									</Carousel.Content>
								</Carousel.Root>
							</div>

							{#each paragraphs as p, i }
								<p class="text-justify">
									<InPlaceEdit bind:value={p} on:submit={submit('text')} />
								</p>
								{#if i === paragraphs.length - 3}
									<div class="mt-6 w-full lg:w-full">
										<Carousel.Root bind:api={apiQuote}>
											<Carousel.Content>
												{#each quotes as quote, i (i)}
													<Carousel.Item>
														<blockquote
															class="border-s-4 border-gray-300 bg-gray-50 p-4 text-xl font-medium italic leading-relaxed text-gray-900 dark:border-gray-500 dark:bg-gray-800 dark:text-white"
														>
															<InPlaceEdit bind:value={quote} on:submit={submit('text')} />
														</blockquote>
													</Carousel.Item>
												{/each}
											</Carousel.Content>
										</Carousel.Root>
									</div>
								{/if}
							{/each}
						</Card.Content>
					</Card.Root>
				</Tabs.Content>
			</Tabs.Root>
		{/if}
		<div
			class="sticky bottom-0 flex w-full flex-col items-center justify-center gap-y-4 border-t bg-background/95 py-4 backdrop-blur supports-[backdrop-filter]:bg-background/60 sm:flex-row sm:gap-x-10 sm:py-8"
		>
			{#if paragraphs.length !== 0}
				<Button
					variant="outline"
					type="submit"
					disabled={submittingSave}
					name="action"
					value="save"
					class="w-full sm:w-auto"
				>
					{#if submittingSave}
						<Loader2 class="mr-2 h-4 w-4 animate-spin" />
					{/if}
					Guardar
				</Button>
				{#if user_id === user}
					<Button
						type="submit"
						name="action"
						disabled={submittingPublish}
						value="publish"
						class="w-full sm:w-auto"
					>
						{#if submittingPublish}
							<Loader2 class="mr-2 h-4 w-4 animate-spin" />
						{/if}
						Submeter
					</Button>
				{/if}
			{/if}
		</div>
	</div>
</form>
