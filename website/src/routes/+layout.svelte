<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();

	const siteSchema = {
		"@context": "https://schema.org",
		"@type": "WebSite",
		"name": "Plezy",
		"url": "https://plezy.app"
	};

	const orgSchema = {
		"@context": "https://schema.org",
		"@type": "Organization",
		"name": "Plezy",
		"url": "https://plezy.app",
		"logo": "https://plezy.app/og/plezy-social.png",
		"sameAs": ["https://github.com/edde746/plezy"]
	};
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	{@html `<script type="application/ld+json">${JSON.stringify(siteSchema)}</script>`}
	{@html `<script type="application/ld+json">${JSON.stringify(orgSchema)}</script>`}
</svelte:head>
{@render children()}
