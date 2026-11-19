import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  host: process.env.HOST || '0.0.0.0',
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'joyn_default_jwt_secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '15d',
  refreshTokenSecret: process.env.REFRESH_TOKEN_SECRET || 'joyn_default_refresh_secret',
  twoFactorApiKey: process.env.TWO_FACTOR_API_KEY || '1eed4550-986f-11f1-9cb1-0200cd936042',
  redis: {
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || undefined,
  },
  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'joyn_db',
  }
};
