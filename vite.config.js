import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
// Deploying the demo under: https://husseinkazoun.github.io/ClickApp/app/
export default defineConfig({ base: "/ClickApp/app/", 
  
  plugins: [react()],
})
