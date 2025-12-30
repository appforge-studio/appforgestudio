import jwt from 'jsonwebtoken';
import { env } from '@env';

const JWT_SECRET = env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRATION = '24h';
const REFRESH_TOKEN_EXPIRATION = '30d';

// In-memory token revocation list (in production, use Redis or database)
const revokedTokens = new Set<string>();

export interface TokenPayload {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

/**
 * Generate a JWT token with user claims and 24-hour expiration
 * @param userId - User ID to include in token
 * @param email - User email to include in token
 * @returns JWT token string
 */
export function generateToken(userId: string, email: string): string {
  const payload: TokenPayload = {
    userId,
    email,
  };
  
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRATION,
  });
}

/**
 * Verify and decode a JWT token
 * @param token - JWT token to verify
 * @returns Decoded token payload if valid
 * @throws Error if token is invalid, expired, or revoked
 */
export function verifyToken(token: string): TokenPayload {
  // Check if token is revoked
  if (revokedTokens.has(token)) {
    throw new Error('Token has been revoked');
  }
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as TokenPayload;
    return decoded;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error('Token has expired');
    }
    if (error instanceof jwt.JsonWebTokenError) {
      throw new Error('Invalid token');
    }
    throw error;
  }
}

/**
 * Generate a new token from a valid existing token
 * @param oldToken - Existing valid token
 * @returns New JWT token with extended expiration
 * @throws Error if old token is invalid
 */
export function refreshToken(oldToken: string): string {
  const decoded = verifyToken(oldToken);
  return generateToken(decoded.userId, decoded.email);
}

/**
 * Revoke a token by adding it to the revocation list
 * @param token - Token to revoke
 */
export function revokeToken(token: string): void {
  revokedTokens.add(token);
}

/**
 * Check if a token is revoked
 * @param token - Token to check
 * @returns True if token is revoked, false otherwise
 */
export function isTokenRevoked(token: string): boolean {
  return revokedTokens.has(token);
}
