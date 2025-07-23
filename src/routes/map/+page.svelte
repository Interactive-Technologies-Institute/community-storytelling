<script lang="ts">
	import Map from './_components/map.svelte';
	import Marker from './_components/marker.svelte';
	import { goto } from '$app/navigation';
	import { fly } from 'svelte/transition';

	export let data;
	let allPins = data.pins;
	let allStories = data.stories;

	let allYears = Array.from({ length: 51 }, (_, i) => 1980 + i);
	let minYear = 1990;
	let maxYear = 2005;

	let timelineEl: HTMLDivElement;

	let mapCenter = { lat: 38.7382, lng: -9.1212 };

	$: filteredPins = allPins.filter(pin => {
		return pin.year >= minYear && pin.year <= maxYear;
	});

	function getYearFromPosition(x: number): number {
		const rect = timelineEl.getBoundingClientRect();
		const relativeX = x - rect.left;
		const yearIndex = Math.round(relativeX / (rect.width / (allYears.length - 1)));
		return allYears[Math.max(0, Math.min(yearIndex, allYears.length - 1))];
	}

	function startDragging(handle: 'min' | 'max') {
		return (event: PointerEvent) => {
			const move = (e: PointerEvent) => {
				const newYear = getYearFromPosition(e.clientX);
				if (handle === 'min') {
					minYear = Math.min(newYear, maxYear);
				} else {
					maxYear = Math.max(newYear, minYear);
				}
			};

			const stop = () => {
				window.removeEventListener('pointermove', move);
				window.removeEventListener('pointerup', stop);
			};

			window.addEventListener('pointermove', move);
			window.addEventListener('pointerup', stop);
		};
	}

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
	<div class="timeline-wrapper">
		<div bind:this={timelineEl} class="timeline">
			{#each allYears as year}
				<div class="tick" style="left: {((year - 1980) / 50) * 100}%">
					<span>{year}</span>
				</div>
			{/each}

			<div
				class="selection"
				style="
					left: {((minYear - 1980) / 50) * 100}%;
					width: {((maxYear - minYear) / 50) * 100}%;
				"
			></div>

			<div
				class="handle"
				style="left: {((minYear - 1980) / 50) * 100}%"
				on:pointerdown={startDragging('min')}
			></div>
			<div
				class="handle"
				style="left: {((maxYear - 1980) / 50) * 100}%"
				on:pointerdown={startDragging('max')}
			></div>
		</div>
		<p class="range-label">De {minYear} até {maxYear}</p>
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
					marker_color={pin.pin_color}
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

	.timeline-wrapper {
		margin: 20px auto;
		width: 100%;
		max-width: 800px;
		position: relative;
		user-select: none;
	}

	.timeline {
		position: relative;
		height: 16px;
		background: #f2f2f2;
		border-radius: 8px;
		overflow: hidden;
	}

	.tick {
		position: absolute;
		top: 0;
		height: 100%;
		width: 1px;
		background: #ccc;
	}

	.tick span {
		position: absolute;
		top: 22px;
		left: 50%;
		transform: translateX(-50%);
		font-size: 10px;
		white-space: nowrap;
		color: #444;
	}

	.selection {
		position: absolute;
		top: 0;
		bottom: 0;
		background-color: rgba(114, 0, 0, 0.4);
		pointer-events: none;
		border-radius: 8px;
	}

	.handle {
		position: absolute;
		top: 50%;
		transform: translate(-50%, -50%);
		width: 20px;
		height: 20px;
		background-color: #720000;
		cursor: ew-resize;
		border-radius: 50%;
		box-shadow: 0 0 2px rgba(0, 0, 0, 0.2);
	}

	.range-label {
		text-align: center;
		margin-top: 10px;
		font-weight: 500;
	}

	.map-container {
		height: 600px;
		width: 100%;
		border-radius: 8px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
	}
</style>
