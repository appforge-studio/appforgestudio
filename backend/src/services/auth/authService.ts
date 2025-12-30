import { hashPassword, verifyPassword } from './passwordUtils.js';
import { generateToken } from './tokenService.js';
import {
  createUser,
  getUserByEmail,
  getUserByProvider,
  checkEmailExists,
} from './userRepository.js';
import {
  addProviderToUser,
} from './providerRepository.js';
import type { User } from '@database/schema/users';

export interface AuthResult {
  success: boolean;
  token?: string;
  user?: User;
  message?: string;
}

export async function authenticateWithEmail(
  email: string,
  password: string
): Promise<AuthResult> {
  if (!email || !password || email.trim() === '' || password.trim() === '') {
    return { success: false, message: 'Email and password are required' };
  }
  
  const user = await getUserByEmail(email);
  if (!user || !user.password) {
    return { success: false, message: 'Invalid credentials' };
  }
  
  const isValid = await verifyPassword(password, user.password);
  if (!isValid) {
    return { success: false, message: 'Invalid credentials' };
  }
  
  const token = generateToken(user.id, user.emailId);
  return { success: true, token, user };
}

export async function registerUser(
  email: string,
  password: string,
  userName?: string
): Promise<AuthResult> {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email || !emailRegex.test(email)) {
    return { success: false, message: 'Invalid email format' };
  }
  
  if (!password || password.length < 8) {
    return { success: false, message: 'Password must be at least 8 characters' };
  }
  
  const emailExists = await checkEmailExists(email);
  if (emailExists) {
    return { success: false, message: 'An account with this email already exists' };
  }
  
  const hashedPassword = await hashPassword(password);
  const user = await createUser(email, userName || email.split('@')[0] || 'User', hashedPassword);
  const userEmail = user.emailId;
  await addProviderToUser(user.id, 'email', userEmail, userEmail);
  
  const token = generateToken(user.id, userEmail);
  return { success: true, token, user };
}

export async function authenticateWithOAuth(
  provider: 'google' | 'apple',
  providerId: string,
  email?: string,
  userName?: string
): Promise<AuthResult> {
  let user = await getUserByProvider(provider, providerId);
  
  if (user) {
    const token = generateToken(user.id, user.emailId);
    return { success: true, token, user };
  }
  
  if (email) {
    user = await getUserByEmail(email);
    if (user) {
      await addProviderToUser(user.id, provider, providerId, email);
      const token = generateToken(user.id, user.emailId);
      return { success: true, token, user };
    }
  }
  
  if (!email) {
    return { success: false, message: 'Email is required for new user registration' };
  }
  
  // OAuth users have verified emails and skip onboarding
  user = await createUser(
    email, 
    userName || email.split('@')[0] || 'User', 
    undefined,
    true, // isEmailVerified
    true  // onboardingCompleted
  );
  const userEmail = user.emailId;
  await addProviderToUser(user.id, provider, providerId, userEmail);
  
  const token = generateToken(user.id, userEmail);
  return { success: true, token, user };
}
