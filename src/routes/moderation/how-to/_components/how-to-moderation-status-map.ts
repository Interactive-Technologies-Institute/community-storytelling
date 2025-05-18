import type { ModerationStatus } from '@/types/types';
import { Badge, BadgeCheck, BadgeInfo, BadgeX, type Icon } from 'lucide-svelte';
import type { ComponentType } from 'svelte';

export const typeMap: Record<ModerationStatus, { label: string; icon: ComponentType<Icon> }> = {
	pending: {
		label: 'Pending',
		icon: Badge,
	},
	approved: {
		label: 'Approved',
		icon: BadgeCheck,
	},
	changes_requested: {
		label: 'Changes Requested',
		icon: BadgeInfo,
	},
	rejected: {
		label: 'Rejected',
		icon: BadgeX,
	},
};
