import '@arrirpc/server';
import { AuthUser } from "../services/authServer";

import { Logger } from 'pino';

declare module '@arrirpc/server' {
    import '@arrirpc/server';

    interface H3EventContext {
        logger?: Logger<never, boolean>;
        user?: AuthUser;
        reqStart?: Date;
    }
    interface ArriEventContext {
        logger?: Logger<never, boolean>;
        user?: AuthUser;
        reqStart?: Date;
        foo?: string;
    }
}
