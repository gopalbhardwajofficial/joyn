import Redis from 'ioredis';
import { config } from '../config/index.js';

// In-memory fallback map for environments without local Redis daemon
const memoryCache = new Map<string, { value: string; expiresAt: number }>();

let redisClient: Redis | null = null;
let isRedisConnected = false;

try {
  redisClient = new Redis({
    host: config.redis.host,
    port: config.redis.port,
    password: config.redis.password,
    lazyConnect: true,
    maxRetriesPerRequest: 1,
    enableOfflineQueue: false,
  });

  redisClient.on('error', (err) => {
    isRedisConnected = false;
  });

  redisClient.connect().then(() => {
    isRedisConnected = true;
    console.log('✅ Connected to Redis Cache Server');
  }).catch(() => {
    console.warn('⚠️ Redis connection failed, falling back to Memory Cache Store.');
    isRedisConnected = false;
  });
} catch (e) {
  console.warn('⚠️ Redis initialization error, using Memory Cache Store.');
}

export async function setCache(key: string, value: string, ttlSeconds: number = 300): Promise<void> {
  if (isRedisConnected && redisClient) {
    try {
      await redisClient.set(key, value, 'EX', ttlSeconds);
      return;
    } catch (e) {
      // Fallthrough to memory store
    }
  }
  memoryCache.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
}

export async function getCache(key: string): Promise<string | null> {
  if (isRedisConnected && redisClient) {
    try {
      return await redisClient.get(key);
    } catch (e) {
      // Fallthrough to memory store
    }
  }
  const item = memoryCache.get(key);
  if (!item) return null;
  if (Date.now() > item.expiresAt) {
    memoryCache.delete(key);
    return null;
  }
  return item.value;
}

export async function deleteCache(key: string): Promise<void> {
  if (isRedisConnected && redisClient) {
    try {
      await redisClient.del(key);
      return;
    } catch (e) {
      // Fallthrough
    }
  }
  memoryCache.delete(key);
}
