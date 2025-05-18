<script lang="ts">
	import { page } from '$app/stores';
	import FeatureWrapper from '@/components/feature-wrapper.svelte';
	import PageHeader from '@/components/page-header.svelte';
	import * as Avatar from '@/components/ui/avatar';
	import { Button } from '@/components/ui/button';
	import * as Card from '@/components/ui/card';
	import { firstAndLastInitials } from '@/utils';
	import { Mail, Map, SquareArrowOutUpRight } from 'lucide-svelte';
	import { MetaTags } from 'svelte-meta-tags';

	export let data;
</script>

<MetaTags title="User Details" description="" />

<PageHeader title="User Details" subtitle="View user details and their contributions" />
<div class="container mx-auto mb-20 flex max-w-3xl flex-col gap-y-8 md:gap-y-10">
	<Card.Root>
		<Card.Header>
			<div class="flex flex-row items-center gap-x-4">
				<Avatar.Root class="h-20 w-20">
					<Avatar.Image src={data.userProfile.avatar} alt={data.userProfile.display_name} />
					<Avatar.Fallback>{firstAndLastInitials(data.userProfile.display_name)}</Avatar.Fallback>
				</Avatar.Root>
				<div>
					<Card.Title class="text-xl">{data.userProfile.display_name}</Card.Title>
					<Card.Description class="text-lg">
						{data.userProfile.type}
					</Card.Description>
				</div>
			</div>
		</Card.Header>
		<Card.Content class="space-y-4">
			<p>{data.userProfile.description ?? 'No description provided'}</p>
			<div class="flex flex-row gap-x-4">
				<Button href="mailto:{data.userProfile.email}" variant="outline">
					<Mail class="mr-2 h-4 w-4" />
					Email
				</Button>
				{#if data.mapPin}
					<Button href="/map?id={data.mapPin.id}&zoom=10" variant="outline">
						<Map class="mr-2 h-4 w-4" />
						View on Map
					</Button>
				{/if}
			</div>
			{#if $page.url.pathname === '/users/me'}
				<Button href="/users/me/edit">Edit Profile</Button>
			{/if}
		</Card.Content>
	</Card.Root>
	<FeatureWrapper feature="howtos">
		<Card.Root>
			<Card.Header>
				<Card.Title>How Tos ({data.howTos.length})</Card.Title>
				<Card.Description>List of How To guides created</Card.Description>
			</Card.Header>
			<Card.Content>
				{#if data.howTos && data.howTos.length > 0}
					<div class="flex flex-wrap gap-4">
						{#each data.howTos as howTo}
							<Button href="/how-to/{howTo.id}" variant="outline" class="max-w-full">
								<span class="truncate">{howTo.label}</span>
								<SquareArrowOutUpRight class="ml-2 h-4 w-4 shrink-0 text-muted-foreground" />
							</Button>
						{/each}
					</div>
				{:else}
					<p class="text-sm text-muted-foreground">User has not created any How Tos</p>
				{/if}
			</Card.Content>
		</Card.Root>
	</FeatureWrapper>
	<FeatureWrapper feature="events">
		<Card.Root>
			<Card.Header>
				<Card.Title>Events ({data.events.length})</Card.Title>
				<Card.Description>List of Events created</Card.Description>
			</Card.Header>
			<Card.Content>
				{#if data.events && data.events.length > 0}
					<div class="flex flex-wrap gap-4">
						{#each data.events as event}
							<Button href="/events/{event.id}" variant="outline" class="max-w-full">
								<span class="truncate">{event.label}</span>
								<SquareArrowOutUpRight class="ml-2 h-4 w-4 shrink-0 text-muted-foreground" />
							</Button>
						{/each}
					</div>
				{:else}
					<p class="text-sm text-muted-foreground">User has not created any Events</p>
				{/if}
			</Card.Content>
		</Card.Root>
	</FeatureWrapper>
</div>
