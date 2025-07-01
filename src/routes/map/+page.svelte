<script lang="ts">
	import Map from './_components/map.svelte';
	import Marker from './_components/marker.svelte';
	import { goto } from '$app/navigation';

	export let data;
	let allPins = data.pins;
	let allStories = data.stories;

	let year = 2000;
	let mapCenter = { lat: 38.736946, lng: -9.142685 };

	$: filteredPins = allPins.filter(pin => pin.year === year);

	let storyLookup: Record<number | string, string> = {};

	$: if (allStories) {
		storyLookup = {};
		for (const story of allStories) {
		storyLookup[story.id] = story.storyteller;
		}
	}

	$: enrichedPins = filteredPins.map(pin => ({
		...pin,
		storyteller: storyLookup[pin.story_id] ?? 'Unknown storyteller'
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
	<div class="year-selector">
		<label for="yearRange">Ano selecionado:</label>
		<input
		id="yearRange"
		type="range"
		min="2000"
		max="2015"
		step="1"
		bind:value={year}
		/>
		<strong>{year}</strong>
	</div>

	<div class="map-container">
		<Map bind:map lng={mapCenter.lng} lat={mapCenter.lat} zoom={13}>
			{#each enrichedPins as pin (pin.story_id)}
				<Marker
					lat={pin.lat}
					lng={pin.lng}
					story_id={pin.story_id}
					year={pin.year}
					title={pin.storyteller}
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

	.year-selector {
		padding: 10px 20px;
		border-radius: 8px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
		width: fit-content;
		margin: 10px auto;
		display: flex;
		align-items: center;
		gap: 10px;
		font-weight: bold;
		z-index: 10;
	}

	.map-container {
		height: 600px;
		width: 100%;
		border-radius: 8px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
	}
</style>
