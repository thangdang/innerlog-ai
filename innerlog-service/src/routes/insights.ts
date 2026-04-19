import { Router, Response } from 'express';
import axios from 'axios';
import { body } from 'express-validator';
import { Checkin, Insight } from '../models';
import { config } from '../config';
import { authMiddleware, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { getCached, setCache } from '../services/cache';

const router = Router();
const INSIGHT_CACHE_TTL = 6 * 60 * 60; // 6h — weekly data, regenerate daily at most

/**
 * @swagger
 * /insights/generate:
 *   post:
 *     summary: Generate AI-powered insights from check-ins
 *     tags: [Insights]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               period:
 *                 type: string
 *                 enum: [7d, 30d, 60d, 90d]
 *                 default: 7d
 *     responses:
 *       201:
 *         description: Insight generated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Insight'
 *       400:
 *         description: No check-ins found for this period
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// POST /api/v1/insights/generate
router.post('/generate',
  authMiddleware,
  body('period').optional().isIn(['7d', '30d', '60d', '90d']).withMessage('Period phải là 7d/30d/60d/90d'),
  validate,
  async (req: AuthRequest, res: Response) => {
  try {
    const { period = '7d' } = req.body;
    const days = parseInt(period) || 7;
    const since = new Date();
    since.setDate(since.getDate() - days);

    const checkins = await Checkin.find({
      user_id: req.userId,
      created_at: { $gte: since },
    }).sort({ created_at: 1 });

    if (checkins.length === 0) {
      res.status(400).json({ error: 'No check-ins found for this period' }); return;
    }

    // Cache key: userId + period + checkin count (changes when new checkins added)
    const cacheKey = `${req.userId}:${period}:${checkins.length}`;
    const cached = await getCached<any>('insight', cacheKey);
    if (cached) {
      const insight = new Insight({
        user_id: req.userId,
        period,
        bullets: cached.bullets,
        meta: cached.metrics,
      });
      await insight.save();
      res.status(201).json({ ...insight.toObject(), cached: true });
      return;
    }

    // Call AI engine (with fallback if offline)
    let aiData: any;
    try {
      const aiResponse = await axios.post(`${config.aiServiceUrl}/ai/analyze`, {
        checkins: checkins.map(c => ({
          mood_score: c.mood_score,
          energy_level: c.energy_level,
          text_note: c.text_note || '',
          created_at: c.created_at,
        })),
      }, { timeout: 15000 });
      aiData = aiResponse.data;
    } catch (err: any) {
      // Fallback: basic local analysis when AI engine is offline
      const moods = checkins.map(c => c.mood_score);
      const avgMood = moods.reduce((a, b) => a + b, 0) / moods.length;
      const moodLabel = avgMood >= 3.5 ? 'tích cực' : avgMood >= 2.5 ? 'trung bình' : 'thấp';
      aiData = {
        bullets: [
          `Tâm trạng trung bình: ${moodLabel} (${avgMood.toFixed(1)}/5).`,
          `Dựa trên ${checkins.length} check-in trong ${days} ngày.`,
          '⚠️ Phân tích chi tiết tạm thời không khả dụng (AI engine offline).',
        ],
        metrics: {
          avg_mood: Math.round(avgMood * 100) / 100,
          mood_trend: 'unknown',
          stress_level: 'unknown',
          top_topics: [],
          positive_score: 0,
        },
      };
    }

    const insight = new Insight({
      user_id: req.userId,
      period,
      bullets: aiData.bullets,
      meta: aiData.metrics,
    });
    await insight.save();

    // Cache the AI result (6h)
    await setCache('insight', cacheKey, aiData, INSIGHT_CACHE_TTL);

    res.status(201).json(insight);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /insights/latest:
 *   get:
 *     summary: Get the latest insight for the current user
 *     tags: [Insights]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Latest insight or empty object
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Insight'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/insights/latest
router.get('/latest', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const insight = await Insight.findOne({ user_id: req.userId }).sort({ created_at: -1 });
    res.json(insight || {});
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /insights/history:
 *   get:
 *     summary: Get insight history with optional period filter
 *     tags: [Insights]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [7d, 30d, 60d, 90d]
 *         description: Filter by period
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Maximum number of insights to return
 *     responses:
 *       200:
 *         description: List of insights
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Insight'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/insights/history
router.get('/history', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { period, limit = '20' } = req.query;
    const filter: any = { user_id: req.userId };
    if (period) filter.period = period;
    const insights = await Insight.find(filter)
      .sort({ created_at: -1 })
      .limit(parseInt(limit as string));
    res.json(insights);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /insights/compare:
 *   get:
 *     summary: Compare two insight periods
 *     tags: [Insights]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: id1
 *         required: true
 *         schema:
 *           type: string
 *         description: First insight ID
 *       - in: query
 *         name: id2
 *         required: true
 *         schema:
 *           type: string
 *         description: Second insight ID
 *     responses:
 *       200:
 *         description: Comparison of two insight periods
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 period1:
 *                   type: object
 *                   properties:
 *                     period:
 *                       type: string
 *                     created_at:
 *                       type: string
 *                       format: date-time
 *                     meta:
 *                       type: object
 *                 period2:
 *                   type: object
 *                   properties:
 *                     period:
 *                       type: string
 *                     created_at:
 *                       type: string
 *                       format: date-time
 *                     meta:
 *                       type: object
 *                 changes:
 *                   type: object
 *                   properties:
 *                     mood_change:
 *                       type: number
 *                     stress_improved:
 *                       type: boolean
 *                     positive_change:
 *                       type: number
 *       400:
 *         description: Missing id1 or id2
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Insight not found
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/insights/compare?id1=&id2= — compare two insight periods
router.get('/compare', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { id1, id2 } = req.query;
    if (!id1 || !id2) { res.status(400).json({ error: 'Provide id1 and id2' }); return; }
    const [insight1, insight2] = await Promise.all([
      Insight.findOne({ _id: id1, user_id: req.userId }),
      Insight.findOne({ _id: id2, user_id: req.userId }),
    ]);
    if (!insight1 || !insight2) { res.status(404).json({ error: 'Insight not found' }); return; }

    const comparison = {
      period1: { period: insight1.period, created_at: insight1.created_at, meta: insight1.meta },
      period2: { period: insight2.period, created_at: insight2.created_at, meta: insight2.meta },
      changes: {
        mood_change: (insight2.meta?.avg_mood || 0) - (insight1.meta?.avg_mood || 0),
        stress_improved: insight1.meta?.stress_level !== insight2.meta?.stress_level,
        positive_change: (insight2.meta?.positive_score || 0) - (insight1.meta?.positive_score || 0),
      },
    };
    res.json(comparison);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
