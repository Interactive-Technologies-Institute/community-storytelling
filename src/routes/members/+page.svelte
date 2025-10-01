<script lang="ts">
	import { onMount } from 'svelte';
	import type { PageData } from './$types';
	import * as Avatar from '$lib/components/ui/avatar';

	export let data: PageData;

	let search = '';
	let results: typeof data.users = [];

	$: results = search.trim()
		? data.users.filter((u) =>
			u.display_name.toLowerCase().includes(search.toLowerCase())
		)
		: [];

	function goToUser(userId: string) {
		window.location.href = `/users/${userId}`;
	}
</script>

<div class="container mx-auto max-w-2xl p-4 sm:p-8 text-center mt-16 sm:mt-20">
	<h1 class="text-3xl sm:text-5xl lg:text-6xl font-bold mb-8 sm:mb-10">
		Procura por membros!
	</h1>

	<input
		type="text"
		placeholder="Procura por membros..."
		bind:value={search}
		class="w-full p-3 border rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 mb-6 text-base sm:text-lg"
	/>

	{#if results.length > 0}
		<!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
		<ul class="space-y-3 text-left">
			<!-- svelte-ignore a11y-click-events-have-key-events -->
			{#each results as user}
				<li
					class="flex items-center gap-3 p-3 border rounded-lg shadow-sm cursor-pointer transition-colors hover:bg-gray-50"
					on:click={() => goToUser(user.id)}
				>
					<Avatar.Root class="h-12 w-12 rounded-full overflow-hidden">
						{#if user.avatar}
							<Avatar.Image src={user.avatarUrl ?? ''} alt={user.display_name} />
						{:else}
							<Avatar.Fallback class="bg-gray-300 flex items-center justify-center font-semibold text-gray-700">
								{user.display_name.slice(0, 2).toUpperCase()}
							</Avatar.Fallback>
						{/if}
					</Avatar.Root>
					<span class="text-lg font-medium">{user.display_name}</span>
				</li>
			{/each}
		</ul>
	{:else if search.trim()}
		<p class="text-gray-500 mt-6 text-base sm:text-lg">Nenhum membro encontrado.</p>
	{/if}
</div>
