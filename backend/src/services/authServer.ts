import { a } from '@arrirpc/schema';

export const AuthUser = a.object('AuthUser', {
    id: a.string(),
    name: a.string(),
    organizationId: a.string(),
});
export type AuthUser = a.infer<typeof AuthUser>;