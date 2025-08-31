<script lang="ts">
	import { Button } from '@/components/ui/button';
	import * as DropdownMenu from '@/components/ui/dropdown-menu';
	import { Moon, Sun } from 'lucide-svelte';
	import { resetMode, setMode } from 'mode-watcher';
</script>

<DropdownMenu.Root>
	<DropdownMenu.Trigger asChild let:builder>
		<Button builders={[builder]} variant="outline" size="icon-sm">
			<Sun
				class="h-4 w-4 rotate-0 scale-100 transition-all duration-[5000] dark:-rotate-90 dark:scale-0"
			/>
			<Moon
				class="absolute h-4 w-4 rotate-90 scale-0 transition-all duration-[5000] dark:rotate-0 dark:scale-100"
			/>
			<span class="sr-only">Toggle theme</span>
		</Button>
	</DropdownMenu.Trigger>
	<DropdownMenu.Content align="end">
		<DropdownMenu.Item on:click={() => setMode('light')}>Modo Claro</DropdownMenu.Item>
		<DropdownMenu.Item on:click={() => setMode('dark')}>Modo Escuro</DropdownMenu.Item>
		<DropdownMenu.Item on:click={() => resetMode()}>Sistema</DropdownMenu.Item>
	</DropdownMenu.Content>
</DropdownMenu.Root>
