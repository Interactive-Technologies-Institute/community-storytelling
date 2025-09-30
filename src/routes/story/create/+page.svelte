<script lang="ts">
	import { Button } from '$lib/components/ui/button';

	let altImg = 'Taking notes';
</script>

<svelte:head>
	<title>Criar história</title>
	<meta name="description" content="Choose whose story to collect" />
</svelte:head>

<div class="container mx-auto space-y-10 pb-10 px-4 sm:px-6 lg:px-8">
	<div>
		<img
			class="mx-auto w-64 sm:w-72 md:w-80"
			src="/app_images/taking_notes.png"
			alt={altImg}
		/>
		<h2 class="pb-4 text-center text-2xl sm:text-3xl md:text-4xl font-semibold tracking-tight text-white transition-colors">
			Está na altura de criar a tua história.
		</h2>

		<div class="flex flex-col md:flex-row justify-center items-center gap-6 md:gap-16 pt-6 pb-6 relative">
			<div class="flex flex-col items-center text-center p-4 md:p-8 w-full md:w-auto">
				<Button
					class="w-full md:w-auto px-6 py-4 md:px-10 md:py-6 text-lg sm:text-xl md:text-2xl"
					href="/story/create/monologue"
				>
					Monólogo
				</Button>
				<p class="pt-4 text-base sm:text-lg md:text-xl text-white">
					Fala sozinho sobre um lugar e partilha a tua visão e experiência pessoal.
				</p>
			</div>

			<div class="hidden md:block w-px h-28 bg-white opacity-30"></div>

			<div class="flex flex-col items-center text-center p-4 md:p-8 w-full md:w-auto">
				<Button
					class="w-full md:w-auto px-6 py-4 md:px-10 md:py-6 text-lg sm:text-xl md:text-2xl"
					href="/story/create/interview"
				>
					Entrevista
				</Button>
				<p class="pt-4 text-base sm:text-lg md:text-xl text-white">
					Conversa com outras pessoas sobre um lugar e explora diferentes perspetivas.
				</p>
			</div>
		</div>
	</div>
</div>

