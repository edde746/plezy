import { enhancedImages } from "@sveltejs/enhanced-img";
import { sveltekit } from "@sveltejs/kit/vite";
import Icons from "unplugin-icons/vite";
import { defineConfig } from "vite";

export default defineConfig({ plugins: [enhancedImages(), sveltekit(), Icons({ compiler: "svelte" })], preview: { allowedHosts: ["*"] } });
