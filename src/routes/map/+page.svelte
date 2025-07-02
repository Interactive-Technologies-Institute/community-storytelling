<script lang="ts">
	import Map from './_components/map.svelte';
	import Marker from './_components/marker.svelte';
	import { goto } from '$app/navigation';
	import { fly } from 'svelte/transition';

	export let data;
	let allPins = data.pins;
	let allStories = data.stories;

	export let selectedDecade = 2000;

	const decades = [1980, 1990, 2000, 2010, 2020];

	function setDecade(decade: number) {
		selectedDecade = decade;
	}


	let mapCenter = { lat: 38.7382, lng: -9.1212 };

	$: filteredPins = allPins.filter(pin => {
		const decadeStart = selectedDecade;
		const decadeEnd = selectedDecade + 9;
		return pin.year >= decadeStart && pin.year <= decadeEnd;
	});

	let storyLookup: Record<number | string, string> = {};

	$: if (allStories) {
		storyLookup = {};
		for (const story of allStories) {
		storyLookup[story.id] = story.title;
		}
	}

	$: enrichedPins = filteredPins.map(pin => ({
		...pin,
		title: storyLookup[pin.story_id] ?? 'TBD'
	}));


	let map: mapboxgl.Map | undefined;

	$: if (map && enrichedPins.length) {
			const firstPin = enrichedPins[0];
			map.setCenter([firstPin.lng, firstPin.lat]);
		}

	function handleNavigate(event: CustomEvent<{ story_id: string | number }>) {
		const storyId = event.detail.story_id;
		goto(`/story/${storyId}`);
	}
</script>

	<div class="wrapper">
		<h2
			class="text-center text-4xl font-bold mb-6"
			in:fly={{ y: -20, duration: 500 }}
		>
			Vamos viajar no tempo!
		</h2>
	<div class="decade-scroller">
		{#each decades as decade}
			<button
				class:active={selectedDecade === decade}
				on:click={() => setDecade(decade)}
			>
			{#if decade === 2020}
				{decade}–
			{:else}
				{decade}–{decade + 9}
			{/if}
			</button>
		{/each}
	</div>
	<div class="map-container">
		<Map bind:map lng={mapCenter.lng} lat={mapCenter.lat} zoom={14}>
			{#each enrichedPins as pin (pin.story_id)}
				<Marker
					lat={pin.lat}
					lng={pin.lng}
					story_id={pin.story_id}
					year={pin.year}
					title={pin.title}
					on:navigate={handleNavigate}
				/>
			{/each}
			</Map>
	</div>
	</div>

	<style>
	.wrapper {
		max-width: 800px;
		margin: 0 auto;
		position: relative;
	}

	.decade-scroller {
		display: flex;
		gap: 12px;
		overflow-x: auto;
		padding: 10px 20px;
		margin-bottom: 20px;
		justify-content: center;
		scroll-snap-type: x mandatory;
	}

	.decade-scroller button {
		background-color: #ad8e03; /* Tailwind: bg-gray-100 */
		border: none;
		padding: 10px 16px;
		border-radius: 9999px;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.2s ease;
		scroll-snap-align: center;
		white-space: nowrap;
	}

	.decade-scroller button:hover {
		background-color: #ff0202; /* Tailwind: bg-gray-200 */
	}

	.decade-scroller button.active {
		background-color: #720000; /* Tailwind: bg-blue-600 */
		color: white;
	}

	.map-container {
		height: 600px;
		width: 100%;
		border-radius: 8px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
	}
</style>
