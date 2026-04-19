import { Router, Response } from 'express';
import { Notification } from '../models';
import { authMiddleware, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * @swagger
 * /notifications:
 *   get:
 *     summary: Get user notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: unread
 *         schema:
 *           type: string
 *           enum: ['true', 'false']
 *         description: Filter by unread status
 *     responses:
 *       200:
 *         description: List of notifications with unread count
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 notifications:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Notification'
 *                 unreadCount:
 *                   type: integer
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// GET /api/v1/notifications
router.get('/', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { unread } = req.query;
    const filter: any = { user_id: req.userId };
    if (unread === 'true') filter.read = false;
    const notifications = await Notification.find(filter)
      .sort({ created_at: -1 })
      .limit(50);
    const unreadCount = await Notification.countDocuments({ user_id: req.userId, read: false });
    res.json({ notifications, unreadCount });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /notifications/{id}/read:
 *   put:
 *     summary: Mark a notification as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Notification ID
 *     responses:
 *       200:
 *         description: Notification marked as read
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// PUT /api/v1/notifications/:id/read
router.put('/:id/read', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, user_id: req.userId },
      { read: true }
    );
    res.json({ message: 'Marked as read' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * @swagger
 * /notifications/read-all:
 *   put:
 *     summary: Mark all notifications as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: All notifications marked as read
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
// PUT /api/v1/notifications/read-all
router.put('/read-all', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    await Notification.updateMany({ user_id: req.userId, read: false }, { read: true });
    res.json({ message: 'All marked as read' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
