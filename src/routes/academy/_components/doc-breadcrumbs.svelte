<script lang="ts">
	import { beforeNavigate } from '$app/navigation';
	import * as Breadcrumb from '@/components/ui/breadcrumb';
	import { ScrollArea } from '@/components/ui/scroll-area';
	import * as Sheet from '@/components/ui/sheet';
	import type { DocGroup } from '@/types/types';
	import { Menu } from 'lucide-svelte';
	import DocGroupTab from './doc-group-tab.svelte';

	export let docs: DocGroup[];
	export let grougSlug: string;
	export let slug: string;
	export let title: string;

	let open = false;

	beforeNavigate(() => {
		open = false;
	});
</script>

<Breadcrumb.Root>
	<Breadcrumb.List>
		<Sheet.Root bind:open>
			<Sheet.Trigger class="flex items-center gap-1 md:hidden">
				<Menu class="h-5 w-5" />
				<span class="sr-only">Toggle academy menu</span>
			</Sheet.Trigger>
			<Sheet.Content side="left" class="pr-0">
				<ScrollArea orientation="both" class="my-4 h-screen pb-10">
					<nav class="flex flex-col items-start gap-y-4">
						{#each docs as docGroup, index}
							<DocGroupTab {index} {docGroup}></DocGroupTab>
						{/each}
					</nav>
				</ScrollArea>
			</Sheet.Content>
		</Sheet.Root>
		<Breadcrumb.Separator class="md:hidden" />
		<Breadcrumb.Item>
			<Breadcrumb.Link href="/academy/{grougSlug}">{grougSlug}</Breadcrumb.Link>
		</Breadcrumb.Item>
		<Breadcrumb.Separator />
		<Breadcrumb.Item>
			<Breadcrumb.Link href="/academy/{grougSlug}/{slug}">{title}</Breadcrumb.Link>
		</Breadcrumb.Item>
	</Breadcrumb.List>
</Breadcrumb.Root>
