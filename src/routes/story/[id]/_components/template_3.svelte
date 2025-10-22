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

	<div class="flex-1">
		{#each data.pub_story_text as p, i (p)}
			<p class="text-justify pt-2">{p}</p>

			{#if i === data.pub_story_text.length - 3}
				<div class="mt-6 w-full">
					<blockquote
						class="border-s-4 border-gray-300 bg-gray-50 p-4 text-xl font-medium italic leading-relaxed text-gray-900 dark:border-gray-500 dark:bg-gray-800 dark:text-white"
					>
						{data.pub_quotes[0]}
					</blockquote>
				</div>
			{/if}
		{/each}
	</div>
</div>
