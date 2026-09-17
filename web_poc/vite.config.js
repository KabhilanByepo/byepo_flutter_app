import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Builds straight into the Flutter app's assets/web_poc/ (declared in
// pubspec.yaml) so `npm run build` is the only step needed before
// `flutter run` picks up the latest web app.
//
// `assetsDir: '.'` keeps the output flat (no nested assets/ subfolder) to
// match pubspec's single non-recursive `assets/web_poc/` entry — Flutter's
// directory asset entries don't bundle nested directories.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: '../assets/web_poc',
    emptyOutDir: true,
    assetsDir: '.',
  },
});
