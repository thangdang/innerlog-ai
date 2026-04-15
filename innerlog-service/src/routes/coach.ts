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

    let aiData: any;
    try {
      const aiResponse = await axios.post(`${config.aiServiceUrl}/ai/coach`, {
        checkins: checkins.map(c => ({
          mood_score: c.mood_score,
          energy_level: c.energy_level,
          created_at: c.created_at.toISOString(),
        })),
      }, { timeout: 15000 });
      aiData = aiResponse.data;
    } catch (err: any) {
      // Fallback: basic local pattern detection when AI engine is offline
      const moods = checkins.map(c => c.mood_score);
      const alerts: any[] = [];

      // Simple mood drop detection
      let drops = 0;
      for (let i = 1; i < moods.length; i++) {
        if (moods[i] < moods[i - 1]) drops++;
        else drops = 0;
        if (drops >= 2) {
          alerts.push({ type: 'mood_drop', message: 'Tâm trạng giảm liên tục. Hãy dành thời gian cho bản thân.', severity: 'warning' });
          break;
        }
      }

      // Simple stress spike
      const recentLow = moods.slice(-5).filter(m => m <= 2).length;
      if (recentLow >= 2) {
        alerts.push({ type: 'stress_spike', message: 'Bạn có vẻ đang stress. Thử nghỉ ngơi hoặc tập thể dục nhẹ.', severity: 'high' });
      }

      aiData = { alerts, should_notify: alerts.length > 0 };
    }

    // Save alerts as notifications
    const alerts = aiData.alerts || [];
    for (const alert of alerts) {
      await new Notification({
        user_id: req.userId,
        type: 'coach',
        title: `Silent Coach: ${alert.type}`,
        message: alert.message,
      }).save();
    }

    res.json(aiData);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
