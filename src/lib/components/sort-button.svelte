<script>
	import { Button } from '@/components/ui/button';
	import { ListFilter } from 'lucide-svelte';
</script>

<Button variant="outline" class="w-10 p-0 md:w-auto md:px-4 md:py-2">
	<ListFilter class="h-4 w-4 md:mr-2" />
	<span class="sr-only md:not-sr-only">Sort by</span>
</Button>
