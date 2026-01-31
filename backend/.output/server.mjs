import { toNodeListener } from '@arrirpc/server';
import { listen } from '@joshmossas/listhen';
import app from './app.mjs';

void listen(toNodeListener(app.h3App), {
    port: process.env.PORT ?? 5000,
    public: true,
    ws: {
        resolve(info) {
            if (app.h3App.websocket?.resolve) {
                return app.h3App.websocket.resolve(info);
            }
            return app.h3App.websocket?.hooks ?? app.h3App.handler?.__websocket__ ?? {};
        }
    },
    http2: false,
    
});