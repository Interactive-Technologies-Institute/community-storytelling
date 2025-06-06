<!--<script lang="ts">
	import ModerationBanner from '@/components/moderation-banner.svelte';
	import * as Avatar from '@/components/ui/avatar';
	import { Button } from '@/components/ui/button';
	import { Card } from '@/components/ui/card';
	import * as Select from '@/components/ui/select';
	import { firstAndLastInitials } from '@/utils';
	import type { Selected } from 'bits-ui';
	import { Store } from 'lucide-svelte';
	import { MetaTags } from 'svelte-meta-tags';
	import type { Writable } from 'svelte/store';
	import { queryParam, ssp } from 'sveltekit-search-params';
	import AddPinButton from './_components/add-pin-button.svelte';
	import DeletePinButton from './_components/delete-pin-button.svelte';
	import Map from './_components/map.svelte';
	import Marker from './_components/marker.svelte';
	import MyPinButton from './_components/my-pin-button.svelte';
	import UpdatePinButton from './_components/update-pin-button.svelte';

	export let data;

	const lng = queryParam('lng', ssp.number(-9.469218750000001), {
		debounceHistory: 1000,
	}) as Writable<number>;
	const lat = queryParam('lat', ssp.number(38.7376572), {
		debounceHistory: 1000,
	}) as Writable<number>;
	const zoom = queryParam('zoom', ssp.number(6), {
		debounceHistory: 1000,
	}) as Writable<number>;

	let selectedUserType: Selected<string> | undefined;
	$: filteredUsers = data.users.filter((user) => {
		return selectedUserType ? user.type === selectedUserType.value : true;
	});
</script>

<MetaTags title="Map" description="Find & share places" />

<div class="relative h-[calc(100dvh-3.5rem)] min-h-[32rem]">
	<Map bind:lng={$lng} bind:lat={$lat} bind:zoom={$zoom}>
		{#each filteredUsers as user (user.id)}
			{#if user?.pin}
				<Marker lng={user.pin.lng} lat={user.pin.lat}>
					<div class="rounded-full border-2 border-primary bg-foreground">
						<Avatar.Root class="h-10 w-10">
							<Avatar.Image src={user.avatar} alt={user.display_name} />
							<Avatar.Fallback>{firstAndLastInitials(user.display_name)}</Avatar.Fallback>
						</Avatar.Root>
					</div>
					<div slot="popup">
						<Card class="max-w-80 px-4">
							<div class="flex flex-row items-center gap-x-2 py-4">
								<Avatar.Root class="h-12 w-12">
									<Avatar.Image src={user.avatar} alt={user.display_name} />
									<Avatar.Fallback>{firstAndLastInitials(user.display_name)}</Avatar.Fallback>
								</Avatar.Root>
								<div>
									<p class="line-clamp-1 font-medium">{user.display_name}</p>
									<p class="text-sm text-muted-foreground">{user.type}</p>
								</div>
							</div>
							<p class="text-sm text-muted-foreground">
								{user.description ?? 'No description provided'}
							</p>
							<Button href="/users/{user.id}" variant="link" class="px-0">View Profile</Button>
						</Card>
					</div>
				</Marker>
			{/if}
		{/each}
		<Marker lat={38.7341425} lng={-9.1246718}>
			<div
				class="flex h-10 w-10 items-center justify-center overflow-hidden rounded-full bg-primary"
			>
				<Store class="h-5 w-5 text-primary-foreground" />
			</div>
		</Marker>
		<div
			class="container absolute left-0 right-0 top-6 flex flex-col items-center gap-y-4 md:top-10"
		>
			<Select.Root
				selected={selectedUserType}
				onSelectedChange={(s) => {
					selectedUserType = s;
				}}
			>
				<Select.Trigger class="w-full bg-background sm:max-w-52">
					<Select.Value placeholder="Filter by type" />
				</Select.Trigger>
				<Select.Content>
					{#each data.userTypes as userType}
						<Select.Item value={userType.slug}>{userType.label}</Select.Item>
					{/each}
				</Select.Content>
			</Select.Root>
			{#if data.moderation && data.moderation[0].status !== 'approved'}
				<ModerationBanner moderation={data.moderation} />
			{/if}
		</div>
		<div class="absolute bottom-12 right-4 flex flex-row gap-x-2">
			{#if data.profile?.pin}
				<UpdatePinButton data={data.updateForm} />
				<DeletePinButton data={data.deleteForm} mapPinId={data.profile.pin.id} />
				<MyPinButton pin={data.profile.pin} />
			{:else}
				<AddPinButton data={data.updateForm} />
			{/if}
		</div>
	</Map>
</div>
-->

<!--<script>
	// Range value bound to slider
	let value = 2000;

	// Total images (0 to 4)
	const maxImages = 4;

	// Compute current image path
	$: imagePath = `map_images/image${value}.jpg`;
</script>
-->
<!-- svelte-ignore a11y-label-has-associated-control -->
<!--
<div class="container">
	<label>
    	Ano selecionado: <strong>{value}</strong>
  	</label>

  	<input
    	type="range"
    	min="2000"
    	max="2015"
    	bind:value
    	step="5"
	/>

  	<img src={imagePath} alt="Dynamic Image" class="preview-image" />
</div>

<style>
	.container {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 1rem;
		margin-top: 2rem;
	}

	.preview-image {
		width: 800px;
		height: auto;
		border-radius: 8px;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
  }
</style>
-->

<script lang="ts">
  import { onMount } from 'svelte';
  import { Loader } from '@googlemaps/js-api-loader';
  import { PUBLIC_GOOGLE_MAPS_KEY } from '$env/static/public';
	import { goto } from '$app/navigation';

  export let data;
  let allPins = data.pins; // array of { lat: number, lng: number, year: number }

  let filteredPins = [];

  let mapContainer: HTMLDivElement;
  let map: google.maps.Map;
  let markers: google.maps.Marker[] = [];

  const apiKey = PUBLIC_GOOGLE_MAPS_KEY;

  let year = 2000;

  // Update filtered pins whenever year changes
  $: filteredPins = allPins.filter(pin => pin.year === year);

  onMount(async () => {
    const loader = new Loader({ apiKey, version: 'weekly' });
    await loader.load();

    map = new google.maps.Map(mapContainer, {
      center: filteredPins.length ? { lat: filteredPins[0].lat, lng: filteredPins[0].lng } : { lat: 38.736946, lng: -9.142685 },
      zoom: 15,
      mapTypeControl: false,
      streetViewControl: false,
      zoomControl: true,
    });

    // Show markers for the initial filtered pins
    updateMarkers();
  });

  // Whenever filteredPins changes, update markers on the map
  $: if (map && filteredPins) {
    updateMarkers();
  }

  function updateMarkers() {
    // Remove old markers
    markers.forEach(marker => marker.setMap(null));
    markers = [];

    // Add new markers
    filteredPins.forEach(({ lat, lng, story_id }) => {
      const marker = new google.maps.Marker({
        position: { lat, lng },
        map,
      });

	  marker.addListener('click', () => {
        goto(`/story/${story_id}`);
      });

      markers.push(marker);
    });

    // Optionally, recenter the map on first filtered pin
    if (filteredPins.length) {
      map.setCenter({ lat: filteredPins[0].lat, lng: filteredPins[0].lng });
    }
  }
</script>

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
    margin: 10px auto; /* center horizontally with margin auto */
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

  <div class="map-container" bind:this={mapContainer}></div>
</div>