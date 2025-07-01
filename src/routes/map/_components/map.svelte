<script lang="ts">
	import 'mapbox-gl/dist/mapbox-gl.css';
	import { setContext, createEventDispatcher } from 'svelte';
	import '../../../app.css';
	import { key, mapboxgl, type MBMapContext } from './mapbox';
	import '@mapbox/mapbox-gl-geocoder/dist/mapbox-gl-geocoder.css';
	import MapboxGeocoder from '@mapbox/mapbox-gl-geocoder';

	export let lng: number;
	export let lat: number;
	export let zoom: number;
	export let map: mapboxgl.Map | undefined;

	setContext<MBMapContext>(key, {
		getMap: () => map,
	});

	const dispatch = createEventDispatcher();

	function updateProps() {
		if (!map) return;
		zoom = map.getZoom();
		lng = map.getCenter().lng;
		lat = map.getCenter().lat;
	}

	function initialize(node: HTMLElement) {
		map = new mapboxgl.Map({
			container: node,
			style: 'mapbox://styles/mapbox/streets-v12',
			center: [lng, lat],
			zoom: zoom,
			minZoom: 1,
			maxZoom: 25,
		});
		map.dragRotate.disable();
		map.touchZoomRotate.disableRotation();
		map.on('move', updateProps);

		const handleClick = (e: mapboxgl.MapMouseEvent) => {
			dispatch('mapClick', {
			lng: e.lngLat.lng,
			lat: e.lngLat.lat,
			});
		};

		map.on('click', handleClick);

		const resizeObserver = new ResizeObserver(() => {
        	map?.resize();
		});
		resizeObserver.observe(node);
		
		const geocoder = new MapboxGeocoder({
			accessToken: mapboxgl.accessToken ?? '',
			mapboxgl: mapboxgl as any,
			marker: false,
		});
		map.addControl(geocoder, 'top-left');

		return {
			destroy() {
				map?.off('move', updateProps);
				map?.off('click', handleClick);
				map?.remove();
				resizeObserver.disconnect();
				map = undefined;
			},
		};
	}
</script>

<div class="h-full w-full" use:initialize>
	{#if map}
		<slot />
	{/if}
</div>

<style>
	:global(.mapboxgl-map) {
		font: inherit;
	}
</style>
