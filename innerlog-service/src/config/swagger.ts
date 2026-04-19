import swaggerJsdoc from 'swagger-jsdoc';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'InnerLog AI – API Documentation',
      version: '1.0.0',
      description: 'AI-powered personal growth tracker. Theo dõi sức khỏe tinh thần, AI phân tích hành vi.',
      contact: { name: 'InnerLog AI Team' },
    },
    servers: [
      { url: '/api/v1', description: 'API v1' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            error: { type: 'string' },
          },
        },
        User: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            email: { type: 'string', format: 'email' },
            display_name: { type: 'string' },
            role: { type: 'string', enum: ['user', 'admin'] },
            plan: { type: 'string', enum: ['free', 'premium'] },
            reminder_enabled: { type: 'boolean' },
            theme: { type: 'string', enum: ['light', 'dark'] },
            notify_coach: { type: 'boolean' },
            notify_reminder: { type: 'boolean' },
            notify_insight: { type: 'boolean' },
            created_at: { type: 'string', format: 'date-time' },
          },
        },
        Checkin: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            user_id: { type: 'string' },
            mood_score: { type: 'integer', minimum: 1, maximum: 5 },
            energy_level: { type: 'string', enum: ['low', 'normal', 'high'] },
            text_note: { type: 'string' },
            tags: { type: 'array', items: { type: 'string' } },
            created_at: { type: 'string', format: 'date-time' },
          },
        },
        Insight: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            user_id: { type: 'string' },
            period: { type: 'string', enum: ['7d', '30d', '60d', '90d'] },
            bullets: { type: 'array', items: { type: 'string' } },
            meta: {
              type: 'object',
              properties: {
                avg_mood: { type: 'number' },
                mood_trend: { type: 'string' },
                stress_level: { type: 'string' },
                top_topics: { type: 'array', items: { type: 'string' } },
                positive_score: { type: 'number' },
              },
            },
            created_at: { type: 'string', format: 'date-time' },
          },
        },
        Goal: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            user_id: { type: 'string' },
            title: { type: 'string' },
            category: { type: 'string', enum: ['study', 'work', 'health', 'finance', 'other'] },
            tasks: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  title: { type: 'string' },
                  done: { type: 'boolean' },
                },
              },
            },
            progress: { type: 'integer', minimum: 0, maximum: 100 },
            status: { type: 'string', enum: ['active', 'completed', 'abandoned'] },
            created_at: { type: 'string', format: 'date-time' },
          },
        },
        Streak: {
          type: 'object',
          properties: {
            current_streak: { type: 'integer' },
            longest_streak: { type: 'integer' },
            total_checkins: { type: 'integer' },
          },
        },
        Notification: {
          type: 'object',
          properties: {
            _id: { type: 'string' },
            user_id: { type: 'string' },
            type: { type: 'string', enum: ['coach', 'reminder', 'insight', 'streak', 'system'] },
            title: { type: 'string' },
            message: { type: 'string' },
            read: { type: 'boolean' },
            created_at: { type: 'string', format: 'date-time' },
          },
        },
        CoachResponse: {
          type: 'object',
          properties: {
            alerts: { type: 'array', items: { type: 'string' } },
            should_notify: { type: 'boolean' },
          },
        },
      },
    },
  },
  apis: ['./src/routes/*.ts'],
};

export const swaggerSpec = swaggerJsdoc(options);
