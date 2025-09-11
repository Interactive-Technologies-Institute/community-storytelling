<script lang="ts">
	import type { PageData } from './$types';
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
</script>

<div class="max-w-2xl mx-auto p-6">
	{#if page === 1}
		<h1 class="text-4xl font-bold mb-4">Your Story: {requestedStory.title}</h1>
		<p class="mb-6 whitespace-pre-line">{formatStoryText(requestedStory.pub_story_text)}</p>

		<button
			on:click={nextPage}
			class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
		>
			Next
		</button>
	{:else if page === 2}
		<h1 class="text-4xl font-bold mb-4">The Requester's Story: {requesterStory.title}</h1>
		<p class="mb-6 whitespace-pre-line">{formatStoryText(requesterStory.pub_story_text)}</p>

		<div class="flex gap-4">
			<button
				on:click={prevPage}
				class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
			>
				Back
			</button>

			<button
				on:click={acceptLink}
				class="px-4 py-2 rounded bg-green-600 text-white hover:bg-green-700"
			>
				Accept
			</button>
		</div>
	{/if}
</div>
