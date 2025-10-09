<script lang="ts">
	import { Button } from '@/components/ui/button';
	import type { PageData } from './$types';
	import { ArrowRight } from 'lucide-svelte';
	export let data: PageData;

	let page = 1;
	const { requestedStory, requesterStory } = data;

	function nextPage() {
		page = 2;
	}

	function prevPage() {
		page = 1;
	}

	const formatStoryText = (text: string | string[]) => {
		if (Array.isArray(text)) {
			return text.map((p) => p.trim() + '\n\n').join('');
		}
		return text;
	};

	async function acceptLink() {
		try {
			const formData = new FormData();
			formData.append('requestedStoryId', requestedStory.id.toString());
			formData.append('requesterStoryId', requesterStory.id.toString());

			const response = await fetch('?/acceptColink', {
				method: 'POST',
				body: formData
			});

			if (response.ok) {
				alert('Ligação aceite!');
				window.location.href = '/story';
			} else {
				alert('Erro ao aceitar a ligação.');
			}
		} catch (err) {
			console.error(err);
			alert('Erro ao aceitar a ligação.');
		}
	}

	async function rejectLink() {
		try {
			const formData = new FormData();
			formData.append('requestedStoryId', requestedStory.id.toString());
			formData.append('requesterStoryId', requesterStory.id.toString());

			const response = await fetch('?/deleteColink', {
				method: 'POST',
				body: formData
			});

			if (response.ok) {
				alert('Ligação rejeitada.');
				window.location.href = '/story';
			} else {
				alert('Erro ao rejeitar a ligação.');
			}
		} catch (err) {
			console.error(err);
			alert('Erro ao rejeitar a ligação.');
		}
	}
</script>

<div class="max-w-3xl mx-auto p-6 sm:p-10 space-y-6">
	{#if page === 1}
		<h1 class="text-2xl sm:text-4xl font-bold mb-4 text-center sm:text-left">
			A tua História: {requestedStory.title}
		</h1>
		<p class="mb-6 whitespace-pre-line text-base sm:text-lg leading-relaxed">
			{formatStoryText(requestedStory.pub_story_text)}
		</p>

		<div class="flex justify-center sm:justify-end">
			<Button class="px-6 py-2 bg-green-600 text-white hover:bg-green-700 w-full sm:w-auto flex items-center justify-center gap-2"
					on:click={nextPage}>
					<ArrowRight />
			</Button>
		</div>

	{:else if page === 2}
		<h1 class="text-2xl sm:text-4xl font-bold mb-4 text-center sm:text-left">
			A História a ser ligada: {requesterStory.title}
		</h1>
		<p class="mb-6 whitespace-pre-line text-base sm:text-lg leading-relaxed">
			{formatStoryText(requesterStory.pub_story_text)}
		</p>

		<div class="flex flex-col sm:flex-row gap-4 justify-center sm:justify-end">
			<button
				on:click={prevPage}
				class="px-6 py-2 rounded-lg bg-gray-500 text-white hover:bg-gray-600 transition-colors w-full sm:w-auto"
			>
				Voltar
			</button>

			<button
				on:click={rejectLink}
				class="px-6 py-2 rounded-lg bg-red-600 text-white hover:bg-red-700 transition-colors w-full sm:w-auto"
			>
				Rejeitar
			</button>

			<button
				on:click={acceptLink}
				class="px-6 py-2 rounded-lg bg-green-600 text-white hover:bg-green-700 transition-colors w-full sm:w-auto"
			>
				Aceitar
			</button>
		</div>
	{/if}
</div>
