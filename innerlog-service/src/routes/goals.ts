import { Router, Response } from 'express';
import { body } from 'express-validator';
import { Goal } from '../models';
import { authMiddleware, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';

const router = Router();

// POST /api/v1/goals
router.post('/',
  authMiddleware,
  body('title').notEmpty().isLength({ max: 200 }).withMessage('Tên mục tiêu không hợp lệ'),
  body('category').optional().isIn(['study', 'work', 'health', 'finance', 'other']),
  validate,
  async (req: AuthRequest, res: Response) => {
  try {
    const { title, category, tasks } = req.body;
    const goal = new Goal({ user_id: req.userId, title, category, tasks });
    await goal.save();
    res.status(201).json(goal);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/goals
router.get('/', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { status } = req.query;
    const filter: any = { user_id: req.userId };
    if (status) filter.status = status;
    const goals = await Goal.find(filter).sort({ created_at: -1 });
    res.json(goals);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/goals/:id
router.put('/:id', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const goal = await Goal.findOneAndUpdate(
      { _id: req.params.id, user_id: req.userId },
      { ...req.body, updated_at: new Date() },
      { new: true }
    );
    if (!goal) { res.status(404).json({ error: 'Not found' }); return; }
    res.json(goal);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/goals/:id/tasks/:taskIndex/toggle — toggle micro-task done
router.put('/:id/tasks/:taskIndex/toggle', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const goal = await Goal.findOne({ _id: req.params.id, user_id: req.userId });
    if (!goal) { res.status(404).json({ error: 'Not found' }); return; }
    const idx = parseInt(req.params.taskIndex);
    if (idx < 0 || idx >= goal.tasks.length) { res.status(400).json({ error: 'Invalid task index' }); return; }

    goal.tasks[idx].done = !goal.tasks[idx].done;

    // Auto-calculate progress
    const doneCount = goal.tasks.filter(t => t.done).length;
    goal.progress = goal.tasks.length > 0 ? Math.round((doneCount / goal.tasks.length) * 100) : 0;
    if (goal.progress === 100) goal.status = 'completed';

    goal.updated_at = new Date();
    await goal.save();
    res.json(goal);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/goals/:id/tasks — add micro-task to goal
router.post('/:id/tasks', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { title } = req.body;
    const goal = await Goal.findOne({ _id: req.params.id, user_id: req.userId });
    if (!goal) { res.status(404).json({ error: 'Not found' }); return; }
    goal.tasks.push({ title, done: false });
    // Recalculate progress
    const doneCount = goal.tasks.filter(t => t.done).length;
    goal.progress = goal.tasks.length > 0 ? Math.round((doneCount / goal.tasks.length) * 100) : 0;
    goal.updated_at = new Date();
    await goal.save();
    res.json(goal);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/goals/:id
router.delete('/:id', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const goal = await Goal.findOneAndDelete({ _id: req.params.id, user_id: req.userId });
    if (!goal) { res.status(404).json({ error: 'Not found' }); return; }
    res.json({ message: 'Deleted' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
