import dotenv from 'dotenv';
dotenv.config({ path: '../.env' });

export const config = {
  port: parseInt(process.env.PORT || '3000'),
  nodeEnv: process.env.NODE_ENV || 'development',
  mongodbUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/innerlog_ai',
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
  aiServiceUrl: process.env.AI_SERVICE_URL || 'http://localhost:5000',
  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-me',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret',
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
};
