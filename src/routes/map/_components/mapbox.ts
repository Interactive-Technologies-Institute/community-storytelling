import mapboxgl from 'mapbox-gl';

mapboxgl.accessToken =
	'pk.eyJ1IjoiaXRpbGFyc3lzIiwiYSI6ImNtY2V4MWQyMDAybnEyanNpbXRteTJ2YXMifQ.kImRpFq1PecY0VPc9wJyXQ';

const key = Symbol();

export type MBMapContext = {
	getMap: () => mapboxgl.Map | undefined;
};

export { key, mapboxgl };
