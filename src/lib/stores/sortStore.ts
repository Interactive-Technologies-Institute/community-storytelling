import { writable } from "svelte/store";

export type SortField = "id" | "likeCount";
export type SortDirection = "asc" | "desc";

export const sortField = writable<SortField>("id");
export const sortDirection = writable<SortDirection>("desc");

export function toggleSort(field: SortField) {
	sortField.update((current) => {
		if (current === field) {
			sortDirection.update((dir) => (dir === "asc" ? "desc" : "asc"));
		} else {
			sortDirection.set("desc");
		}
		return field;
	});
}