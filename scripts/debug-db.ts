
import { types } from '../database/schema/types';
import { cities } from '../database/schema/cities';
import { westernHoroscope } from '../database/schema/western_horoscope';
import { nakshatras } from '../database/schema/vedic_horoscope';

import { readFileSync } from 'fs';
import { parse } from 'csv-parse/sync';
import { config } from 'dotenv';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { ulid } from 'ulidx';

console.log('All external libs imported successfully');

