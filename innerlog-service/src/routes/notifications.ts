import { Router, Response } from 'express';
import { Notification } from '../models';
import { authMiddleware, AuthRequest } from '../middleware/auth';

const router = Router();

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
