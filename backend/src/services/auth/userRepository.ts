import { eq, and } from 'drizzle-orm';
import { getDrizzle } from '@database/postgres';
import { Users, type User, type NewUser } from '@database/schema/users';
import { AuthProviders } from '@database/schema/auth_providers';
import { ulid } from 'ulidx';

const db = getDrizzle();

/**
 * Create a new user record
 * @param email - User email
 * @param userName - User name
 * @param password - Optional hashed password (null for OAuth-only users)
 * @param isEmailVerified - Whether email is verified (true for OAuth users)
 * @param onboardingCompleted - Whether onboarding is completed (true for OAuth users)
 * @returns Created user
 */
export async function createUser(
  email: string,
  userName: string,
  password?: string,
  isEmailVerified?: boolean,
  onboardingCompleted?: boolean
): Promise<User> {
  const newUser: NewUser = {
    id: ulid(),
    emailId: email,
    userName,
    password: password || null,
    isEmailVerified: isEmailVerified ?? false,
    onboardingCompleted: onboardingCompleted ?? false,
  };
  
  const [user] = await db.insert(Users).values(newUser).returning();
  return user;
}

/**
 * Get user by email
 * @param email - User email
 * @returns User if found, null otherwise
 */
export async function getUserByEmail(email: string): Promise<User | null> {
  const [user] = await db
    .select()
    .from(Users)
    .where(eq(Users.emailId, email))
    .limit(1);
  
  return user || null;
}

/**
 * Get user by ID
 * @param id - User ID
 * @returns User if found, null otherwise
 */
export async function getUserById(id: string): Promise<User | null> {
  const [user] = await db
    .select()
    .from(Users)
    .where(eq(Users.id, id))
    .limit(1);
  
  return user || null;
}

/**
 * Get user by OAuth provider
 * @param provider - Provider type ('google', 'apple', 'email')
 * @param providerId - Provider-specific user ID
 * @returns User if found, null otherwise
 */
export async function getUserByProvider(
  provider: 'google' | 'apple' | 'email',
  providerId: string
): Promise<User | null> {
  const [result] = await db
    .select({ user: Users })
    .from(AuthProviders)
    .innerJoin(Users, eq(AuthProviders.userId, Users.id))
    .where(
      and(
        eq(AuthProviders.provider, provider),
        eq(AuthProviders.providerId, providerId)
      )
    )
    .limit(1);
  
  return result?.user || null;
}

/**
 * Check if an email already exists
 * @param email - Email to check
 * @returns True if email exists, false otherwise
 */
export async function checkEmailExists(email: string): Promise<boolean> {
  const user = await getUserByEmail(email);
  return user !== null;
}
