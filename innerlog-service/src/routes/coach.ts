import { Router, Response } from 'express';
import axios from 'axios';
import { Checkin, Notification } from '../models';
import { config } from '../config';
import { authMiddleware, AuthRequest } from '../middleware/auth';

const router = Router();

// POST /api/v1/coach/check — run silent coach analysis
router.post('/check', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const since = new Date();
    since.setDate(since.getDate() - 14);
    const checkins = await Checkin.find({
      user_id: req.userId,
      created_at: { $gte: since },
    }).sort({ created_at: 1 });

    if (checkins.length < 3) {
      res.json({ alerts: [], should_notify: false, message: 'Not enough data' }); return;
    }

    const aiResponse = await axios.post(`${config.aiServiceUrl}/ai/coach`, {
      checkins: checkins.map(c => ({
        mood_score: c.mood_score,
        energy_level: c.energy_level,
        created_at: c.created_at.toISOString(),
      })),
    });

    // Save alerts as notifications
    const alerts = aiResponse.data.alerts || [];
    for (const alert of alerts) {
      await new Notification({
        user_id: req.userId,
        type: 'coach',
        title: `Silent Coach: ${alert.type}`,
        message: alert.message,
      }).save();
    }

    res.json(aiResponse.data);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
