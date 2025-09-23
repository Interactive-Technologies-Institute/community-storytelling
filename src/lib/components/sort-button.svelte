<script lang="ts">
	import { cn } from "$lib/utils.js";
	import { Button } from "@/components/ui/button";
	import * as Command from "@/components/ui/command";
	import * as Popover from "@/components/ui/popover";
	import { Check, ListFilter } from "lucide-svelte";
	import { sortField, sortDirection, toggleSort, type SortField } from "@/stores/sortStore";

	let open = false;

	const options: { label: string; value: SortField }[] = [
		{ label: "Data de Criação", value: "id" },
		{ label: "Likes", value: "likeCount" }
	];

	function handleSelect(currentValue: SortField) {
		toggleSort(currentValue);
		open = false;
	}
</script>

<Popover.Root bind:open>
	<Popover.Trigger asChild let:builder>
		<Button
			builders={[builder]}
			variant="outline"
			class="w-10 p-0 md:w-auto md:px-4 md:py-2"
		>
			<div class="relative">
				<ListFilter class="h-4 w-4 md:mr-2" />
				{#if $sortField}
					<div class="absolute -right-1 -top-1 flex h-2 w-2 rounded-full bg-primary md:mr-2"></div>
				{/if}
			</div>
			<span class="sr-only md:not-sr-only">Ordenar</span>
		</Button>
	</Popover.Trigger>

	<Popover.Content class="mt-2 w-[200px] p-0" align="start" side="bottom">
		<Command.Root>
			<Command.Input placeholder="Ordenar por..." />
			<Command.List>
				<Command.Empty>Nenhuma opção encontrada.</Command.Empty>
				<Command.Group>
					{#each options as option}
						<Command.Item
							value={option.value}
							onSelect={() => handleSelect(option.value)}
						>
							<div
								class={cn(
									"mr-2 flex h-4 w-4 items-center justify-center rounded-sm border border-primary",
									$sortField === option.value
										? "bg-primary text-primary-foreground"
										: "opacity-50 [&_svg]:invisible"
								)}
							>
								<Check class="h-4 w-4" />
							</div>
							<span>{option.label}</span>
							{#if $sortField === option.value}
								<span class="ml-auto text-xs font-mono">
									{$sortDirection === "asc" ? "↑" : "↓"}
								</span>
							{/if}
						</Command.Item>
					{/each}
				</Command.Group>

				{#if $sortField}
					<Command.Separator />
					<Command.Item
						class="justify-center text-center"
						onSelect={() => {
							sortField.set("id");
							sortDirection.set("desc");
							open = false;
						}}
					>
						Reset sorting
					</Command.Item>
				{/if}
			</Command.List>
		</Command.Root>
	</Popover.Content>
</Popover.Root>
