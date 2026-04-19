import { Router, Response } from 'express';
import { body } from 'express-validator';
import { Goal } from '../models';
import { authMiddleware, AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';

const router = Router();

/**
 * @swagger
 * /goals:
 *   post:
 *     summary: Create a new goal
 *     tags: [Goals]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *                 maxLength: 200
 *               category:
 *                 type: string
 *                 enum: [study, work, health, finance, other]
 *               tasks:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     title:
 *                       type: string
 *                     done:
 *                       type: boolean
 *     responses:
 *       201:
 *         description: Goal created
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Goal'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
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

/**
 * @swagger
 * /goals:
 *   get:
 *     summary: Get all goals with optional status filter
 *     tags: [Goals]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, completed, abandoned]
 *         description: Filter by goal status
 *     responses:
 *       200:
 *         description: List of goals
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Goal'
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
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

/**
 * @swagger
 * /goals/{id}:
 *   put:
 *     summary: Update a goal
 *     tags: [Goals]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Goal ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               category:
 *                 type: string
 *                 enum: [study, work, health, finance, other]
 *               status:
 *                 type: string
 *                 enum: [active, completed, abandoned]
 *     responses:
 *       200:
 *         description: Updated goal
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Goal'
 *       404:
 *         description: Goal not found
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

/**
 * @swagger
 * /goals/{id}/tasks/{taskIndex}/toggle:
 *   put:
 *     summary: Toggle a micro-task done status within a goal
 *     tags: [Goals]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Goal ID
 *       - in: path
 *         name: taskIndex
 *         required: true
 *         schema:
 *           type: integer
 *         description: Index of the task to toggle
 *     responses:
 *       200:
 *         description: Goal with updated task status and progress
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Goal'
 *       400:
 *         description: Invalid task index
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Goal not found
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

/**
 * @swagger
 * /goals/{id}/tasks:
 *   post:
 *     summary: Add a micro-task to a goal
 *     tags: [Goals]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Goal ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *     responses:
 *       200:
 *         description: Goal with new task added
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Goal'
 *       404:
 *         description: Goal not found
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

/**
 * @swagger
 * /goals/{id}:
 *   delete:
 *     summary: Delete a goal
 *     tags: [Goals]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Goal ID
 *     responses:
 *       200:
 *         description: Goal deleted
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       404:
 *         description: Goal not found
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
