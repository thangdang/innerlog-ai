/**
 * Redis cache for AI responses.
 * Key: sha256(normalized text) with prefix per endpoint.
 * TTL: 6h for insights (weekly data changes), 1h for coach.
 */
import Redis from 'ioredis';
import crypto from 'crypto';
import { config } from '../config';
import { logger } from '../config/logger';

let redis: Redis | null = null;

function getRedis(): Redis {
  if (!redis) {
    redis = new Redis(config.redisUrl, {
      maxRetriesPerRequest: 1,
      lazyConnect: true,
      retryStrategy: (times) => (times > 3 ? null : Math.min(times * 200, 2000)),
    });
    redis.on('error', (err) => logger.debug(`Redis cache error: ${err.message}`));
    redis.connect().catch(() => {});
  }
  return redis;
}

function hashKey(prefix: string, text: string): string {
  const hash = crypto.createHash('sha256').update(text).digest('hex').slice(0, 16);
  return `ai:${prefix}:${hash}`;
}

export async function getCached<T>(prefix: string, key: string): Promise<T | null> {
  try {
    const data = await getRedis().get(hashKey(prefix, key));
    if (data) {
      logger.debug(`Cache HIT: ${prefix}`);
      return JSON.parse(data) as T;
    }
  } catch { /* Redis down — skip */ }
  return null;
}

export async function setCache(prefix: string, key: string, data: any, ttl: number): Promise<void> {
  try {
    await getRedis().set(hashKey(prefix, key), JSON.stringify(data), 'EX', ttl);
  } catch { /* Redis down — skip */ }
}
