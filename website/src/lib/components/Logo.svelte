<script lang="ts">
  import logoUrl from '$lib/assets/favicon.svg';

  let { class: className = '' }: { class?: string } = $props();
</script>

<img
  src={logoUrl}
  alt=""
  aria-hidden="true"
  draggable="false"
  class={className}
/>

<style>
  img {
    display: block;
    object-fit: contain;
  }
</style>
