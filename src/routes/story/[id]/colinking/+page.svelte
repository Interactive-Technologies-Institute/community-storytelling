<script lang="ts">
	import { applyAction, deserialize } from '$app/forms';
	export let data;

	let altImg = 'Logic and Emotion';
	let selectedStory: string = "";
	let userStoryId: number = data.story.id; 

	const linkedStoryIds: number[] = data.story.colinked_stories ?? [];

	const selectableStories = data.myStories.filter(s => !linkedStoryIds.includes(s.id));

	async function submitColinkRequest(event: Event) {
		event.preventDefault();

        let newFormData = new FormData();

        newFormData.append("requested_story_id", String(userStoryId));
        newFormData.append("requester_story_id", String(selectedStory));

		const response = await fetch('?/sendNotification', {
			method: 'POST',
			body: newFormData,
			headers: {
				'x-sveltekit-action': 'true',
			},
		});

		const result = deserialize(await response.text());
		applyAction(result);
	}
</script>

<div class="flex flex-col items-center justify-center p-6 rounded-2xl shadow bg-background space-y-6">
	<img class="mx-auto" src="/app_images/logic-and-emotion-9.16.12 PM.png" alt={altImg} width={700} />
	<h2 class="text-4xl font-bold text-center">Conecta as tuas histórias</h2>
	<h2 class="text-1xl font-bold text-center">Escolhe que história queres ligar com esta</h2>

	<form
		method="POST"
		action="?/sendNotification"
		on:submit|preventDefault={submitColinkRequest}
		enctype="multipart/form-data"
		class="flex flex-col gap-y-10"
	>
		<input type="hidden" name="requested_story_id" value={userStoryId} />

		<select
			name="requester_story_id"
			bind:value={selectedStory}
			required
			class="w-full sm:w-[300px] border rounded-lg px-3 py-2 text-center mx-auto"
		>
			<option value="">Escolhe uma história</option>
			{#each selectableStories as story}
				<option value={story.id}>{story.title}</option>
			{/each}
		</select>

		{#if selectedStory}
			<div class="flex flex-col items-center gap-2 mt-2">
				<p class="text-lg text-center">
					<strong>Selecionado:</strong> {selectableStories.find(s => s.id === Number(selectedStory))?.title}
				</p>

				<button
					type="submit"
					name="intent"
					value="sendNotification"
					class="px-6 py-2 bg-blue-600 text-white rounded-lg flex items-center gap-2"
					disabled={!selectedStory}
				>
					<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v8m-4-4h8" />
					</svg>
					Conectar
				</button>
			</div>
		{/if}
	</form>
</div>
