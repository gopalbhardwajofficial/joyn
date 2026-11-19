import { FastifyRequest, FastifyReply } from 'fastify';

interface RateLimitRecord {
  count: number;
  resetAt: number;
}

const ipBuckets = new Map<string, RateLimitRecord>();

// Clean up expired buckets every 2 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, record] of ipBuckets.entries()) {
    if (now > record.resetAt) {
      ipBuckets.delete(key);
    }
  }
}, 120000);

export async function rateLimitMiddleware(req: FastifyRequest, reply: FastifyReply) {
  // Exclude health check and public assets from strict rate limits
  const path = req.url || '';
  if (path === '/health' || path.startsWith('/public/')) {
    return;
  }

  const clientIp = (req.headers['x-forwarded-for'] as string) || req.ip || '127.0.0.1';
  const now = Date.now();

  // Strict limit for sensitive auth endpoints (15 req / min) vs general (300 req / min)
  const isAuthStrict = path.includes('/auth/send-otp') || path.includes('/auth/verify-otp');
  const maxRequests = isAuthStrict ? 15 : 300;
  const windowMs = 60 * 1000; // 1 minute window

  const bucketKey = `${clientIp}:${isAuthStrict ? 'auth' : 'gen'}`;
  let record = ipBuckets.get(bucketKey);

  if (!record || now > record.resetAt) {
    record = { count: 1, resetAt: now + windowMs };
    ipBuckets.set(bucketKey, record);
  } else {
    record.count++;
  }

  reply.header('X-RateLimit-Limit', maxRequests.toString());
  reply.header('X-RateLimit-Remaining', Math.max(0, maxRequests - record.count).toString());
  reply.header('X-RateLimit-Reset', Math.ceil(record.resetAt / 1000).toString());

  if (record.count > maxRequests) {
    const retryAfterSec = Math.ceil((record.resetAt - now) / 1000);
    reply.header('Retry-After', retryAfterSec.toString());
    return reply.status(429).send({
      success: false,
      error: 'Too Many Requests',
      message: `Rate limit exceeded. Try again in ${retryAfterSec} seconds.`,
      statusCode: 429
    });
  }
}

