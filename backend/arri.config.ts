import { defineConfig, servers, generators } from "arri";
import { join } from "path";
import path from 'node:path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  server: servers.tsServer({
    entry: join(__dirname, "src/app.ts"),
    port: 5000,
    esbuild: {
      alias: {
        '@database': path.resolve(__dirname, '../database'),
        '@env': path.resolve(__dirname, '../env.ts'),
      }
    },
    // Configure server for large file uploads
    nitro: {
      experimental: {
        wasm: true
      },
      // Increase body size limit to 600MB
      routeRules: {
        '/media/upload': {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
          }
        }
      }
    }
  }),
  generators: [
    // Frontend client generation
    generators.dartClient({
      clientName: "ArriClient",
      outputFile: path.resolve(
        __dirname,
        "../frontend/lib/services/arri_client.rpc.dart"
      ),
    }),
    generators.dartClient({
      clientName: "ArriClient",
      outputFile: path.resolve(
        __dirname,
        "../admin_pannel/lib/services/arri_client.rpc.dart"
      ),
    }),
  ],
});
