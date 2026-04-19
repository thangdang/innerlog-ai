import { Router, Response } from 'express';
import { body, query } from 'express-validator';
import { Checkin, Streak } from '../models';
import { authMiddleware, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';

const router = Router();

// Helper: update streak on new checkin
async function updateStreak(userId: string) {
  const today = new Date().toISOString().slice(0, 10);
  let streak = await Streak.findOne({ user_id: userId });
  if (!streak) {
    streak = new Streak({ user_id: userId, current_streak: 1, longest_streak: 1, last_checkin_date: today, total_checkins: 1 });
    await streak.save();
    return streak;
  }

  const lastDate = streak.last_checkin_date;
  if (lastDate === today) {
    streak.total_checkins += 1;
  } else {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().slice(0, 10);

    if (lastDate === yesterdayStr) {
      streak.current_streak += 1;
    } else {
      streak.current_streak = 1;
    }
    streak.total_checkins += 1;
    streak.last_checkin_date = today;
  }

  if (streak.current_streak > streak.longest_streak) {
    streak.longest_streak = streak.current_streak;
  }
  streak.updated_at = new Date();
  await streak.save();
  return streak;
}

/**
 * @swagger
 * /checkins:
 *   post:
 *     summary: Create a new check-in
 *     tags: [Checkins]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - mood_score
 *               - energy_level
 *             properties:
 *               mood_score:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               energy_level:
 *                 type: string
 *                 enum: [low, normal, high]
 *               text_note:
 *                 type: string
 *                 maxLength: 500
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Check-in created with updated streak
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 checkin:
 *                   $ref: '#/components/schemas/Checkin'
 *                 streak:
 *                   $ref: '#/components/schemas/Streak'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// POST /api/v1/checkins
router.post('/',
  authMiddleware,
  body('mood_score').isInt({ min: 1, max: 5 }).withMessage('Mood phải từ 1-5'),
  body('energy_level').isIn(['low', 'normal', 'high']).withMessage('Energy phải là low/normal/high'),
  body('text_note').optional().isString().isLength({ max: 500 }),
  validate,
  async (req: AuthRequest, res: Response) => {
  try {
    const { mood_score, energy_level, text_note, tags } = req.body;
    const checkin = new Checkin({ user_id: req.userId, mood_score, energy_level, text_note, tags });
    await checkin.save();
    const streak = await updateStreak(req.userId!);
    res.status(201).json({ checkin, streak });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /checkins:
 *   get:
 *     summary: Get check-ins with pagination and date filtering
 *     tags: [Checkins]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: from
 *         schema:
 *           type: string
 *           format: date
 *         description: Start date filter
 *       - in: query
 *         name: to
 *         schema:
 *           type: string
 *           format: date
 *         description: End date filter
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
 *           default: 50
 *           maximum: 100
 *         description: Items per page
 *     responses:
 *       200:
 *         description: Paginated list of check-ins
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Checkin'
 *                 total:
 *                   type: integer
 *                 page:
 *                   type: integer
 *                 limit:
 *                   type: integer
 *                 hasMore:
 *                   type: boolean
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/checkins?from=&to=&page=1&limit=50
router.get('/', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { from, to } = req.query;
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
    const skip = (page - 1) * limit;
    const filter: any = { user_id: req.userId };
    if (from || to) {
      filter.created_at = {};
      if (from) filter.created_at.$gte = new Date(from as string);
      if (to) filter.created_at.$lte = new Date(to as string);
    }
    const [checkins, total] = await Promise.all([
      Checkin.find(filter).sort({ created_at: -1 }).skip(skip).limit(limit),
      Checkin.countDocuments(filter),
    ]);
    res.json({ data: checkins, total, page, limit, hasMore: skip + checkins.length < total });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /checkins/{id}:
 *   put:
 *     summary: Update a check-in
 *     tags: [Checkins]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Check-in ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               mood_score:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 5
 *               energy_level:
 *                 type: string
 *                 enum: [low, normal, high]
 *               text_note:
 *                 type: string
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Updated check-in
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Checkin'
 *       404:
 *         description: Check-in not found
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
// PUT /api/v1/checkins/:id
router.put('/:id', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const checkin = await Checkin.findOneAndUpdate(
      { _id: req.params.id, user_id: req.userId },
      req.body,
      { new: true }
    );
    if (!checkin) { res.status(404).json({ error: 'Not found' }); return; }
    res.json(checkin);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /checkins/{id}:
 *   delete:
 *     summary: Delete a check-in
 *     tags: [Checkins]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Check-in ID
 *     responses:
 *       200:
 *         description: Check-in deleted
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       404:
 *         description: Check-in not found
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
// DELETE /api/v1/checkins/:id
router.delete('/:id', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const checkin = await Checkin.findOneAndDelete({ _id: req.params.id, user_id: req.userId });
    if (!checkin) { res.status(404).json({ error: 'Not found' }); return; }
    res.json({ message: 'Deleted' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /checkins/streak:
 *   get:
 *     summary: Get current streak information
 *     tags: [Checkins]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Current streak data
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Streak'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/checkins/streak — current streak info
router.get('/streak', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const streak = await Streak.findOne({ user_id: req.userId });
    res.json(streak || { current_streak: 0, longest_streak: 0, total_checkins: 0 });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /checkins/heatmap:
 *   get:
 *     summary: Get mood heatmap data for a year (365 days)
 *     tags: [Checkins]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *         description: Year to get heatmap for (defaults to current year)
 *     responses:
 *       200:
 *         description: Daily mood averages for heatmap
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   date:
 *                     type: string
 *                     format: date
 *                   avg_mood:
 *                     type: number
 *                   count:
 *                     type: integer
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/checkins/heatmap?year=2026 — mood heatmap data (365 days)
router.get('/heatmap', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const year = parseInt(req.query.year as string) || new Date().getFullYear();
    const start = new Date(`${year}-01-01`);
    const end = new Date(`${year}-12-31T23:59:59`);
    const checkins = await Checkin.find({
      user_id: req.userId,
      created_at: { $gte: start, $lte: end },
    }).sort({ created_at: 1 });

    // Group by date, average mood per day
    const heatmap: Record<string, { mood: number; count: number }> = {};
    for (const c of checkins) {
      const day = c.created_at.toISOString().slice(0, 10);
      if (!heatmap[day]) heatmap[day] = { mood: 0, count: 0 };
      heatmap[day].mood += c.mood_score;
      heatmap[day].count += 1;
    }
    const data = Object.entries(heatmap).map(([date, v]) => ({
      date,
      avg_mood: Math.round((v.mood / v.count) * 10) / 10,
      count: v.count,
    }));
    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /checkins/stats:
 *   get:
 *     summary: Get mood trends and statistics for charts
 *     tags: [Checkins]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days to include in stats
 *     responses:
 *       200:
 *         description: Mood trends and energy distribution
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 moodTrend:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       date:
 *                         type: string
 *                         format: date
 *                       avg:
 *                         type: number
 *                 energyDist:
 *                   type: object
 *                   properties:
 *                     low:
 *                       type: integer
 *                     normal:
 *                       type: integer
 *                     high:
 *                       type: integer
 *                 avgMood:
 *                   type: number
 *                 totalCheckins:
 *                   type: integer
 *                 days:
 *                   type: integer
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/checkins/stats — trends & stats for charts
router.get('/stats', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    const since = new Date();
    since.setDate(since.getDate() - days);
    const checkins = await Checkin.find({
      user_id: req.userId,
      created_at: { $gte: since },
    }).sort({ created_at: 1 });

    const dailyMood: Record<string, number[]> = {};
    const dailyEnergy: Record<string, string[]> = {};
    for (const c of checkins) {
      const day = c.created_at.toISOString().slice(0, 10);
      if (!dailyMood[day]) dailyMood[day] = [];
      if (!dailyEnergy[day]) dailyEnergy[day] = [];
      dailyMood[day].push(c.mood_score);
      dailyEnergy[day].push(c.energy_level);
    }

    const moodTrend = Object.entries(dailyMood).map(([date, moods]) => ({
      date,
      avg: Math.round((moods.reduce((a, b) => a + b, 0) / moods.length) * 10) / 10,
    }));

    const energyDist = { low: 0, normal: 0, high: 0 };
    checkins.forEach(c => { energyDist[c.energy_level] += 1; });

    const totalMood = checkins.reduce((s, c) => s + c.mood_score, 0);
    const avgMood = checkins.length > 0 ? Math.round((totalMood / checkins.length) * 10) / 10 : 0;

    res.json({ moodTrend, energyDist, avgMood, totalCheckins: checkins.length, days });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
