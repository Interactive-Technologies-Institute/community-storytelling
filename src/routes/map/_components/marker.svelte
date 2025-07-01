<script lang="ts">
	import { getContext, createEventDispatcher } from 'svelte';
	import { key, mapboxgl, type MBMapContext } from './mapbox';

	const { getMap } = getContext<MBMapContext>(key);
	const dispatch = createEventDispatcher();

	export let lng: number;
	export let lat: number;
	export let story_id: string | number;
	export let disableClick = false;
	export let year: number;
	export let title: string;

	let marker: mapboxgl.Marker | undefined;
	let popup: mapboxgl.Popup | undefined;
	let el: HTMLElement;

	function onNavigate() {
		// Dispatch custom event to notify parent to navigate
		dispatch('navigate', { story_id });
	}

	function initialize(node: HTMLElement) {
		el = node;
		const map = getMap();

		if (map) {
			popup = new mapboxgl.Popup({
			closeButton: true,
			closeOnClick: true,
			offset: 40,
			anchor: 'bottom',
			maxWidth: '200px',
			}).setHTML(`
			<div style="text-align:center; font-family: Arial, sans-serif; background-color: black; color: white; padding: 10px;">
				${title} (${year})
				<button id="navigate-btn" style="padding: 6px 12px; background:#d93025; color:white; border:none; border-radius:4px; cursor:pointer;">
				Ver História
				</button>
			</div>
			`);

			marker = new mapboxgl.Marker(el)
			.setLngLat([lng, lat])
			.addTo(map);

			if (disableClick) {
				marker.getElement().style.pointerEvents = 'none';
			}

			else{
				marker.setPopup(popup);
				popup.on('open', () => {
				const btn = document.getElementById('navigate-btn');
				if (btn) {
					btn.onclick = onNavigate;
				}
				});
			}
		}

		return {
			destroy() {
			marker?.remove();
			marker = undefined;
			popup?.remove();
			popup = undefined;
			},
		};
		}

	$: if (marker) {
		marker.setLngLat([lng, lat]);
	}
</script>

<div use:initialize class="pin">
	<slot />
</div>

<style>
	.pin {
		position: relative;
		width: 30px;
		height: 42px;
		cursor: pointer;
		transform: translate(-50%, -100%);
	}
	.pin::before {
		content: "";
		position: absolute;
		top: 0;
		left: 50%;
		transform: translateX(-50%);
		width: 30px;
		height: 30px;
		background: #d93025;
		border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
		border: 2px solid white;
		z-index: 2;
	}
	.pin::after {
		content: "";
		position: absolute;
		bottom: 0;
		left: 50%;
		transform: translateX(-50%);
		width: 14px;
		height: 14px;
		background: #d93025;
		border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
		clip-path: polygon(50% 100%, 0 0, 100% 0);
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
		border: 2px solid white;
		z-index: 1;
	}
	:global(.mapboxgl-popup-content) {
		background: black !important;
		padding: 0 !important;
		box-shadow: none !important;
		border-radius: 8px !important;
		color: white !important;
	}

	:global(.mapboxgl-popup-tip) {
		display: none !important;
	}

	:global(.mapboxgl-popup-close-button) {
		width: 32px;      
		height: 32px;
		font-size: 28px;  
		top: 8px;         
		right: 8px;       
		background-color: rgba(255, 255, 255, 0.8); 
		border-radius: 50%; 
		line-height: 30px;  
		text-align: center;  
		cursor: pointer;
		box-shadow: 0 2px 6px rgba(0,0,0,0.3);
		transition: background-color 0.2s ease;
	}

	:global(.mapboxgl-popup-close-button:hover) {
		background-color: rgba(255, 0, 0, 0.9); 
	}

</style>
