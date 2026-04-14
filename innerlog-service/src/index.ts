import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { config } from './config';
import { connectDatabase } from './config/database';
import { logger } from './config/logger';
import authRoutes from './routes/auth';
import checkinRoutes from './routes/checkins';
import insightRoutes from './routes/insights';
import goalRoutes from './routes/goals';
import dashboardRoutes from './routes/dashboard';
import coachRoutes from './routes/coach';
import notificationRoutes from './routes/notifications';

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/checkins', checkinRoutes);
app.use('/api/v1/insights', insightRoutes);
app.use('/api/v1/goals', goalRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/coach', coachRoutes);
app.use('/api/v1/notifications', notificationRoutes);

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'innerlog-service' });
});

// Start
async function start() {
  await connectDatabase();
  app.listen(config.port, () => {
    logger.info(`innerlog-service running on port ${config.port}`);
  });
}

start().catch((err) => {
  logger.error('Failed to start:', err);
  process.exit(1);
});
