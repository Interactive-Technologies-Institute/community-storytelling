<script lang="ts">
	import * as AlertDialog from '@/components/ui/alert-dialog';
	import { unpublishStorySchema, type UnpublishStorySchema } from '@/schemas/story';
	import { superForm, type Infer, type SuperValidated } from 'sveltekit-superforms';
	import { zodClient } from 'sveltekit-superforms/adapters';

	export let open = false;
	export let storyId: number;
  export let storyOwner: string;
	export let data: SuperValidated<Infer<UnpublishStorySchema>>;

	const form = superForm(data, {
		validators: zodClient(unpublishStorySchema),
	});

	const { form: formData, enhance } = form;

</script>

<AlertDialog.Root bind:open>
  <AlertDialog.Content>
    <form
      id="unpublish-story"
      method="POST"
      action="?/unpublish"
      use:enhance
      class="space-y-4"
    >
      <input type="hidden" name="id" value={storyId} />
      <input type="hidden" name="userId" value={storyOwner} />

      <AlertDialog.Header>
        <AlertDialog.Title>Você tem certeza?</AlertDialog.Title>
        <AlertDialog.Description>
          Esta ação é reversível, mas fará com que a história não esteja disponível para o público.
        </AlertDialog.Description>
      </AlertDialog.Header>

      <div class="space-y-2">
        <label for="comment" class="block text-sm font-medium">Comentário para o autor</label>
        <textarea
          name="comment"
  		  bind:value={$formData.comment}
          class="w-full rounded border px-2 py-1"
          rows="4"
          placeholder="Explica as mudanças que queres feitas para publicares a história"
        />
      </div>

      <AlertDialog.Footer>
        <AlertDialog.Cancel type="button">Cancelar</AlertDialog.Cancel>
        <AlertDialog.Action on:click={form.submit}>Continuar</AlertDialog.Action>
      </AlertDialog.Footer>
    </form>
  </AlertDialog.Content>
</AlertDialog.Root>
