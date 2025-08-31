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

<MetaTags title="Detalhes do utilizador" description="" />

<PageHeader title="Detalhes do utilizador" subtitle="Ver detalhes do utilizador e as suas contribuições" />
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
			<p>{data.userProfile.description ?? 'Nenhuma descrição foi adicionada'}</p>
			<div class="flex flex-row gap-x-4">
				<Button href="mailto:{data.userProfile.email}" variant="outline">
					<Mail class="mr-2 h-4 w-4" />
					Email
				</Button>
			</div>
			{#if $page.url.pathname === '/users/me'}
				<Button href="/users/me/edit">Editar Perfil</Button>
			{/if}
		</Card.Content>
	</Card.Root>
	{#if $page.url.pathname === '/users/me'}
		<FeatureWrapper feature="events">
			<Card.Root>
				<Card.Header>
					<Card.Title>Eventos ({data.events.length})</Card.Title>
					<Card.Description>Lista of Eventos criados</Card.Description>
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
						<p class="text-sm text-muted-foreground">Utilizador não criou Eventos</p>
					{/if}
				</Card.Content>
			</Card.Root>
		</FeatureWrapper>
	{/if}
	<FeatureWrapper feature="stories">
		<Card.Root>
			<Card.Header>
				<Card.Title>Histórias Publicadas ({data.stories.length})</Card.Title>
				<Card.Description>Lista de Histórias Criadas</Card.Description>
			</Card.Header>
			<Card.Content>
				{#if data.stories && data.stories.length > 0}
					<div class="flex flex-wrap gap-4">
						{#each data.stories as story}
							<Button href="/story/{story.id}" variant="outline" class="max-w-full">
								<span class="truncate">{story.title}</span>
								<SquareArrowOutUpRight class="ml-2 h-4 w-4 shrink-0 text-muted-foreground" />
							</Button>
						{/each}
					</div>
				{:else}
					<p class="text-sm text-muted-foreground">Utilizador não criou Histórias</p>
				{/if}
			</Card.Content>
		</Card.Root>
	</FeatureWrapper>
</div>
