import { Router, Response } from 'express';
import axios from 'axios';
import { Checkin, Insight } from '../models';
import { config } from '../config';
import { authMiddleware, AuthRequest } from '../middleware/auth';

const router = Router();

// POST /api/v1/insights/generate
router.post('/generate', authMiddleware, async (req: AuthRequest, res: Response) => {
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

    // Call AI engine
    const aiResponse = await axios.post(`${config.aiServiceUrl}/ai/analyze`, {
      checkins: checkins.map(c => ({
        mood_score: c.mood_score,
        energy_level: c.energy_level,
        text_note: c.text_note || '',
        created_at: c.created_at,
      })),
    });

    const insight = new Insight({
      user_id: req.userId,
      period,
      bullets: aiResponse.data.bullets,
      meta: aiResponse.data.metrics,
    });
    await insight.save();
    res.status(201).json(insight);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/insights/latest
router.get('/latest', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const insight = await Insight.findOne({ user_id: req.userId }).sort({ created_at: -1 });
    res.json(insight || {});
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

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
