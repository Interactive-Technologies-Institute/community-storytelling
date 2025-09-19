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
	export let marker_color: string = '#ff0000';
	export let initial: string = '';

	let marker: mapboxgl.Marker | undefined;
	let popup: mapboxgl.Popup | undefined;
	let el: HTMLElement;

	function onNavigate() {
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
				<div style="
					font-family: Arial, sans-serif; 
					background-color: black; 
					color: white; 
					padding: 10px 12px 12px 12px; 
					position: relative;
					display: flex; 
					flex-direction: column; 
					align-items: center;
					gap: 8px;
					text-align: center;
				">
					<div style="font-weight: bold; font-size: 14px; padding-right: 20px;">
						${title} (${year})
					</div>
					<button id="navigate-btn" style="
						padding: 6px 12px; 
						background:#3b82f6; 
						color:white; 
						border:none; 
						border-radius:4px; 
						cursor:pointer;
					">
						Ver História
					</button>
				</div>
			`);


			marker = new mapboxgl.Marker(el, { anchor: 'bottom' })
				.setLngLat([lng, lat])
				.addTo(map);

			if (disableClick) {
				marker.getElement().style.pointerEvents = 'none';
			} else {
				marker.setPopup(popup);
				popup.on('open', () => {
					const btn = document.getElementById('navigate-btn');
					if (btn) btn.onclick = onNavigate;
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

	$: if (marker) marker.setLngLat([lng, lat]);

	$: pinStyle = `
		background: ${marker_color};
		border: 2px solid white;
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
	`;
</script>

<div use:initialize class="pin-wrapper">
	<div class="pin">
		<div class="pin-head" style={pinStyle}>
			<span class="pin-initial">{initial}</span>
		</div>
		<div class="pin-tail" style={pinStyle}></div>
	</div>
</div>

<style>
.pin {
	position: relative;
	width: 30px;
	height: 42px;
	cursor: pointer;
}

.pin-wrapper {
	position: relative;
	width: 0;
	height: 0;
	display: flex;
	justify-content: center;
	align-items: flex-end;
	transform: translateY(-100%);
}

.pin-head {
	position: absolute;
	top: 0;
	left: 50%;
	transform: translateX(-50%);
	width: 30px;
	height: 30px;
	border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
	z-index: 2;
	display: flex;
	align-items: center;
	justify-content: center;
	color: white;
	font-weight: bold;
	font-size: 14px;
	user-select: none;
}

.pin-initial {
	pointer-events: none;
}

.pin-tail {
	position: absolute;
	bottom: 0;
	left: 50%;
	transform: translateX(-50%);
	width: 14px;
	height: 14px;
	border-radius: 50% 50% 50% 50% / 60% 60% 40% 40%;
	clip-path: polygon(50% 100%, 0 0, 100% 0);
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
