<script lang="ts">
	import { Input } from '@/components/ui/input';
	import * as Tabs from '@/components/ui/tabs';
	import MapModerationTable from './_components/map-moderation-table.svelte';

	export let data;
</script>

<Tabs.Content value="users" class="mt-8 flex flex-col gap-y-4">
	<div class="flex flex-1 flex-row gap-x-2 sm:gap-x-4 md:flex-auto">
		<Input placeholder="Pesquisa..." class="flex-1 sm:max-w-64"></Input>
	</div>
	<MapModerationTable mapPins={data.mapPins} updateModerationForm={data.updateModerationForm} />
</Tabs.Content>
