import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/ClickApp/', // required for GitHub Pages under /ClickApp/
})
