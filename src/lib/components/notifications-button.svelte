<script lang="ts">
	import { enhance } from '$app/forms';
	import { beforeNavigate } from '$app/navigation';
	import { Button } from '@/components/ui/button';
	import * as Popover from '@/components/ui/popover';
	import { ScrollArea } from '@/components/ui/scroll-area';
	import { Separator } from '@/components/ui/separator';
	import type { Notification, NotificationType } from '@/types/types';
	import dayjs from 'dayjs';
	import { Check, Inbox } from 'lucide-svelte';

	export let notifications: Notification[];
	$: unreadCount = notifications.filter((notification) => !notification.read).length;

	let open = false;
	beforeNavigate(() => {
		open = false;
	});

	const notificationTypeToLabel: Record<NotificationType, string> = {
		howto_pending: 'O seu guia está pendente de moderação',
		howto_changes_requested: 'O seu guia precisa de alterações',
		howto_approved: 'O seu guia foi aprovado',
		howto_rejected: 'O seu guia foi rejeitado',
		event_pending: 'O seu evento está pendente de moderação',
		event_changes_requested: 'O seu evento precisa de alterações',
		event_approved: 'O seu evento foi aprovado',
		event_rejected: 'O seu evento foi rejeitado',
		map_pin_pending: 'O seu marcador está pendente de moderação',
		map_pin_changes_requested: 'O seu marcador precisa de alterações',
		map_pin_approved: 'O seu marcador foi aprovado',
		map_pin_rejected: 'O seu marcador foi rejeitado',
		colinking_pending: 'Pedido de ligação de histórias',
	};

	function getNotificationHref(notification: Notification): string {
		switch (notification.type) {
			case 'howto_pending':
			case 'howto_changes_requested':
			case 'howto_approved':
			case 'howto_rejected':
				return `/how-to/${notification.data.howto_id ?? 'error'}`;
			case 'event_pending':
			case 'event_changes_requested':
			case 'event_approved':
			case 'event_rejected':
				return `/events/${notification.data.event_id ?? 'error'}`;
			case 'map_pin_pending':
			case 'map_pin_changes_requested':
			case 'map_pin_approved':
			case 'map_pin_rejected':
				return `/map?id=${notification.data.map_pin_id ?? 'error'}`;
			default:
				return 'error';
		}
	}
</script>

<Popover.Root bind:open>
	<Popover.Trigger asChild let:builder>
		<Button variant="outline" size="icon-sm" builders={[builder]}>
			<div class="relative">
				<Inbox class="h-4 w-4" />
				{#if unreadCount > 0}
					<div class="absolute -right-1 -top-1 flex h-2 w-2 rounded-full bg-primary"></div>
				{/if}
			</div>
		</Button>
	</Popover.Trigger>
	<Popover.Content class="w-80 p-0" align="end">
		<div class="flex flex-col gap-y-1 p-4">
			<p class="font-medium leading-none">Notificações</p>
			<p class="text-sm text-muted-foreground">
				{#if unreadCount > 0}
					Tens {unreadCount} {unreadCount === 1 ? 'notification' : 'notifications'} não lidas
				{:else}
					Sem notificações por ler
				{/if}
			</p>
		</div>
		<Separator />
		<ScrollArea>
			<div class="flex max-h-56 flex-col gap-y-2 py-2">
				{#each notifications as notification (notification.id)}
					<form method="POST" action="/?/readNotification" use:enhance>
						<input type="hidden" name="id" value={notification.id} />
						<Button
							href={getNotificationHref(notification)}
							on:click={(event) => {
								event.preventDefault();
								event.currentTarget.closest('form')?.requestSubmit();
								window.location.href = getNotificationHref(notification);
							}}
							variant="ghost"
							class="mx-2 flex h-auto flex-col items-start gap-y-1 px-2"
						>
							<div class="flex flex-row items-center gap-x-2">
								{#if !notification.read}
									<span class="h-2 w-2 rounded-full bg-primary"></span>
								{/if}
								<p class="text-sm font-medium leading-none">
									{notificationTypeToLabel[notification.type]}
								</p>
							</div>
							<p class="text-sm text-muted-foreground">
								{dayjs(notification.inserted_at).fromNow()}
							</p>
						</Button>
					</form>
				{/each}
			</div>
		</ScrollArea>
		<div class="p-4">
			<form method="POST" action="/?/readAllNotifications" use:enhance>
				<Button type="submit" class="w-full">
					<Check class="mr-2 h-4 w-4" />
					Marcar todas como lidas
				</Button>
			</form>
		</div>
	</Popover.Content>
</Popover.Root>
