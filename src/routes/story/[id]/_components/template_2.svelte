<script lang="ts">
	export let data;
</script>

<div class="container mx-auto space-y-10 pb-10">
	<div class="flex flex-col md:flex-row md:items-start md:gap-4">
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
			<div class="flex justify-end mt-4">
				<blockquote
					class="border-s-4 border-gray-300 bg-gray-50 p-2 text-xl font-medium italic leading-relaxed text-gray-900 dark:border-gray-500 dark:bg-gray-800 dark:text-white max-w-2xl"
				>
					{data.pub_quotes[0]}
				</blockquote>
			</div>

			{#each data.pub_story_text as element (element)}
				<p class="pt-2 text-justify">{element}</p>
			{/each}
		</div>
	</div>
</div>
