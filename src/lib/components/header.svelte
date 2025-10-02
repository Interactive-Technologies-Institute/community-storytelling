<script lang="ts">
	import ModeToggle from '@/components/mode-toggle.svelte';
	import MainNav from '@/components/nav/main-nav.svelte';
	import MobileNav from '@/components/nav/mobile-nav.svelte';
	import UserNav from '@/components/nav/user-nav.svelte';
	import type { Notification, UserProfile, UserRole } from '@/types/types';
	import NotificationsButton from './notifications-button.svelte';
	import { Button } from './ui/button';

	export let role: UserRole | null;
	export let profile: UserProfile | null;
	export let notifications: Notification[];
</script>

<header
	class="sticky top-0 z-50 w-full border-b bg-background/95 shadow-sm backdrop-blur supports-[backdrop-filter]:bg-background/60"
>
	<div class="container flex h-14 items-center">
		<MainNav />
		<MobileNav />
		<div class="ml-auto flex items-center gap-x-2 sm:gap-x-4 md:justify-end">
			<ModeToggle />
			{#if profile && role}
				<NotificationsButton {notifications} />
				<UserNav {role} {profile} />
			{:else}
				<Button variant="outline" size="sm" href="/sign-in">Entrar</Button>
				<Button size="sm" href="/sign-up">Inscrever</Button>
			{/if}
		</div>
	</div>
</header>
