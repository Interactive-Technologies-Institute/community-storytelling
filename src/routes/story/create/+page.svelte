<script lang="ts">
	import { Button } from '$lib/components/ui/button';

	let altImg = 'Taking notes';
</script>

<svelte:head>
	<title>Criar história</title>
	<meta name="description" content="Choose whose story to collect" />
</svelte:head>

<div class="container mx-auto space-y-10 pb-10">
	<div>
		<img class="mx-auto" src="/app_images/taking_notes.png" alt={altImg} width={280} />
		<h2 class="pb-2 text-center text-3xl font-semibold tracking-tight transition-colors">
			Está na altura de criar a tua história.
		</h2>
		<div class="flex justify-center items-center gap-16 pb-6 pt-6 relative">
			<!-- Monólogo -->
			<div class="flex flex-col items-center text-center p-8">
				<Button class="p-10" href="/story/create/monologue">Monólogo</Button>
				<p class="pt-4 text-lg text-white">
				Fala sozinho sobre um lugar e partilha a tua visão e experiência pessoal.
				</p>
			</div>

			<!-- Separator -->
			<div class="w-px h-24 bg-white opacity-30"></div>

			<!-- Entrevista -->
			<div class="flex flex-col items-center text-center p-8">
				<Button class="p-10" href="/story/create/interview">Entrevista</Button>
				<p class="pt-4 text-lg text-white">
				Conversa com outras pessoas sobre um lugar e explora diferentes perspetivas.
				</p>
			</div>
		</div>
	</div>
</div>
