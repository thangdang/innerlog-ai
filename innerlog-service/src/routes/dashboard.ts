import { Router, Response } from 'express';
import { User, Checkin, Insight, Goal, Streak } from '../models';
import { authMiddleware, requireAdmin, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * @swagger
 * /dashboard:
 *   get:
 *     summary: Get admin dashboard overview statistics
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard overview with key metrics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 totalUsers:
 *                   type: integer
 *                 premiumUsers:
 *                   type: integer
 *                 newUsersWeek:
 *                   type: integer
 *                 activeUsers:
 *                   type: integer
 *                 retentionRate:
 *                   type: integer
 *                 totalCheckins:
 *                   type: integer
 *                 checkinsToday:
 *                   type: integer
 *                 totalInsights:
 *                   type: integer
 *                 totalGoals:
 *                   type: integer
 *                 avgMoodWeek:
 *                   type: number
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
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

/**
 * @swagger
 * /dashboard/users:
 *   get:
 *     summary: Get paginated user list for admin
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Items per page
 *       - in: query
 *         name: plan
 *         schema:
 *           type: string
 *           enum: [free, premium]
 *         description: Filter by user plan
 *     responses:
 *       200:
 *         description: Paginated user list
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 users:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 limit:
 *                   type: integer
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
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

/**
 * @swagger
 * /dashboard/chart:
 *   get:
 *     summary: Get daily signups and check-ins chart data
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days to include
 *     responses:
 *       200:
 *         description: Chart data with labels, signups, and check-ins arrays
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 labels:
 *                   type: array
 *                   items:
 *                     type: string
 *                     format: date
 *                 signups:
 *                   type: array
 *                   items:
 *                     type: integer
 *                 checkins:
 *                   type: array
 *                   items:
 *                     type: integer
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
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

/**
 * @swagger
 * /dashboard/streaks:
 *   get:
 *     summary: Get top streaks leaderboard
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Top 20 streaks with user info
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Streak'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
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
