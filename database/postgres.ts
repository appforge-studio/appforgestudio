import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import type { PostgresJsDatabase } from "drizzle-orm/postgres-js";
import { DATABASE_URL } from "@env";

// Database connection string from environment variable

// Export the client for manual queries if needed
let db: PostgresJsDatabase | undefined;
let client: postgres.Sql | undefined;

// Function to get drizzle instance
export function getDrizzle(): PostgresJsDatabase {
  if (db) return db;
  
  if (!client) {
    client = postgres(DATABASE_URL!);
  }
  
  db = drizzle(client);
  return db;
}

// Function to close the database connection
export function closeDatabase(): void {
  if (client) {
    client.end();
    client = undefined;
    db = undefined;
  }
}
