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
		// Redirect to the user's page
		window.location.href = `/users/${userId}`;
	}
</script>

<div class="container mx-auto p-4 text-center mt-20">
	<h1 class="text-6xl font-bold mb-10">Procura por membros!</h1>
	<input
		type="text"
		placeholder="Search members..."
		bind:value={search}
		class="w-full p-2 border rounded mb-4"
	/>

	{#if results.length > 0}
		<!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
		<ul class="space-y-2">
			<!-- svelte-ignore a11y-click-events-have-key-events -->
			{#each results as user}
				<li
					class="flex items-center gap-2 p-2 border rounded cursor-pointer hover:bg-gray-100"
					on:click={() => goToUser(user.id)}
				>
					<Avatar.Root class="h-10 w-10">
						{#if user.avatar}
							<Avatar.Image src={user.avatarUrl ?? ''} alt={user.display_name} />
						{:else}
							<Avatar.Fallback>{user.display_name.slice(0, 2).toUpperCase()}</Avatar.Fallback>
						{/if}
					</Avatar.Root>
					<span>{user.display_name}</span>
				</li>
			{/each}
		</ul>
	{:else if search.trim()}
		<p>No users found.</p>
	{/if}
</div>