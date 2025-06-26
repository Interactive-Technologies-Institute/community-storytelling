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
			Está na altura de criar a sua própria história.
		</h2>
		<span class="flex justify-center gap-2 pb-3 pt-3">
			<span><Button class="p-10" href="/story/create/interview">Entrevista</Button></span>
		</span>
	</div>
</div>
