<script lang="ts">
	export let data;
</script>

<div class="flex flex-col md:flex-row md:items-start md:gap-4 mb-6">
	<div class="w-full md:max-w-md lg:max-w-sm flex-shrink-0 text-center md:text-left">
		<h2 class="text-4xl sm:text-5xl font-bold mb-4 break-words">
			{data.title}
		</h2>
		<img
			src={data.pub_selected_images[0]}
			alt={'Fotografia de ' + data.storyteller}
			class="w-full h-auto rounded-lg object-cover"
		/>
	</div>

	<div class="flex-1 mt-4 md:mt-0">
		{#each data.pub_story_text as p}
			<p class="text-justify mb-3">{p}</p>
		{/each}
	</div>
</div>

