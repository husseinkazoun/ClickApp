import { defineConfig } from 'vite';

export default defineConfig({
  /** Project Pages live at /ClickApp/ */
  base: '/ClickApp/',
  /** Build to docs/ so GitHub Pages can serve from the branch */
  build: { outDir: 'docs', emptyOutDir: false },
  server: { open: '/brand.html' }
});
