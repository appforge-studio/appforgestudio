import { eq, and } from 'drizzle-orm';
import { getDrizzle } from '@database/postgres';
import { AuthProviders, type AuthProvider, type NewAuthProvider } from '@database/schema/auth_providers';
import { ulid } from 'ulidx';

const db = getDrizzle();

/**
 * Add an authentication provider to a user
 * @param userId - User ID
 * @param provider - Provider type ('google', 'apple', 'email')
 * @param providerId - Provider-specific user ID
 * @param providerEmail - Optional email from provider
 * @returns Created auth provider record
 */
export async function addProviderToUser(
  userId: string,
  provider: 'google' | 'apple' | 'email',
  providerId: string,
  providerEmail?: string
): Promise<AuthProvider> {
  const newProvider: NewAuthProvider = {
    id: ulid(),
    userId,
    provider,
    providerId,
    providerEmail: providerEmail || null,
  };
  
  const results = await db
    .insert(AuthProviders)
    .values(newProvider)
    .returning();
  
  return results[0]!;
}

/**
 * Get all authentication providers for a user
 * @param userId - User ID
 * @returns Array of auth provider records
 */
export async function getProvidersByUserId(userId: string): Promise<AuthProvider[]> {
  return db
    .select()
    .from(AuthProviders)
    .where(eq(AuthProviders.userId, userId));
}

/**
 * Get a specific provider by provider type and provider ID
 * @param provider - Provider type ('google', 'apple', 'email')
 * @param providerId - Provider-specific user ID
 * @returns Auth provider record if found, null otherwise
 */
export async function getProviderByProviderIdAndType(
  provider: 'google' | 'apple' | 'email',
  providerId: string
): Promise<AuthProvider | null> {
  const results = await db
    .select()
    .from(AuthProviders)
    .where(
      and(
        eq(AuthProviders.provider, provider),
        eq(AuthProviders.providerId, providerId)
      )
    )
    .limit(1);
  
  return results[0] || null;
}
