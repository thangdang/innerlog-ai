import { Router, Response } from 'express';
import { User, Checkin, Insight, Goal, Streak } from '../models';
import { authMiddleware, requireAdmin, AuthRequest } from '../middleware/auth';

const router = Router();

// GET /api/v1/dashboard — admin overview
router.get('/', authMiddleware, requireAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalCheckins = await Checkin.countDocuments();
    const totalInsights = await Insight.countDocuments();
    const totalGoals = await Goal.countDocuments();

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const checkinsToday = await Checkin.countDocuments({ created_at: { $gte: today } });

    const premiumUsers = await User.countDocuments({ plan: 'premium' });

    // Recent 7 days mood average
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const recentCheckins = await Checkin.find({ created_at: { $gte: weekAgo } });
    const avgMood = recentCheckins.length > 0
      ? recentCheckins.reduce((sum, c) => sum + c.mood_score, 0) / recentCheckins.length
      : 0;

    // New users this week
    const newUsersWeek = await User.countDocuments({ created_at: { $gte: weekAgo } });

    // Active users (checked in last 7 days)
    const activeUserIds = await Checkin.distinct('user_id', { created_at: { $gte: weekAgo } });
    const activeUsers = activeUserIds.length;

    // Retention rate
    const retentionRate = totalUsers > 0 ? Math.round((activeUsers / totalUsers) * 100) : 0;

    res.json({
      totalUsers,
      premiumUsers,
      newUsersWeek,
      activeUsers,
      retentionRate,
      totalCheckins,
      checkinsToday,
      totalInsights,
      totalGoals,
      avgMoodWeek: Math.round(avgMood * 100) / 100,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/dashboard/users — user list for admin
router.get('/users', authMiddleware, requireAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const { page = '1', limit = '20', plan } = req.query;
    const filter: any = {};
    if (plan) filter.plan = plan;
    const users = await User.find(filter)
      .sort({ created_at: -1 })
      .skip((parseInt(page as string) - 1) * parseInt(limit as string))
      .limit(parseInt(limit as string));
    const total = await User.countDocuments(filter);
    res.json({ users, total, page: parseInt(page as string), limit: parseInt(limit as string) });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/dashboard/chart — daily signups & checkins for last 30 days
router.get('/chart', authMiddleware, requireAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    const since = new Date();
    since.setDate(since.getDate() - days);

    const users = await User.find({ created_at: { $gte: since } });
    const checkins = await Checkin.find({ created_at: { $gte: since } });

    const dailySignups: Record<string, number> = {};
    const dailyCheckins: Record<string, number> = {};

    for (let i = 0; i < days; i++) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const key = d.toISOString().slice(0, 10);
      dailySignups[key] = 0;
      dailyCheckins[key] = 0;
    }

    users.forEach(u => {
      const key = u.created_at.toISOString().slice(0, 10);
      if (dailySignups[key] !== undefined) dailySignups[key]++;
    });
    checkins.forEach(c => {
      const key = c.created_at.toISOString().slice(0, 10);
      if (dailyCheckins[key] !== undefined) dailyCheckins[key]++;
    });

    const labels = Object.keys(dailySignups).sort();
    res.json({
      labels,
      signups: labels.map(l => dailySignups[l]),
      checkins: labels.map(l => dailyCheckins[l]),
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/dashboard/streaks — top streaks leaderboard
router.get('/streaks', authMiddleware, requireAdmin, async (req: AuthRequest, res: Response) => {
  try {
    const streaks = await Streak.find()
      .sort({ current_streak: -1 })
      .limit(20)
      .populate('user_id', 'email display_name plan');
    res.json(streaks);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
