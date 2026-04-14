import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { User } from '../models';
import { config } from '../config';
import { authMiddleware, AuthRequest } from '../middleware/auth';

const router = Router();

function generateTokens(userId: string) {
  const token = jwt.sign({ id: userId, role: 'user' }, config.jwt.secret, { expiresIn: config.jwt.expiresIn });
  const refreshToken = jwt.sign({ id: userId }, config.jwt.refreshSecret, { expiresIn: config.jwt.refreshExpiresIn });
  return { token, refreshToken };
}

// POST /api/v1/auth/register
router.post('/register', async (req: Request, res: Response) => {
  try {
    const { email, password, display_name } = req.body;
    const exists = await User.findOne({ email });
    if (exists) { res.status(400).json({ error: 'Email already registered' }); return; }

    const user = new User({ email, password_hash: password, display_name });
    await user.save();
    const tokens = generateTokens(user._id as string);
    res.status(201).json({ user, ...tokens });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/auth/login
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email }).select('+password_hash');
    if (!user || !(await user.comparePassword(password))) {
      res.status(401).json({ error: 'Invalid credentials' }); return;
    }
    const tokens = generateTokens(user._id as string);
    res.json({ user, ...tokens });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/auth/refresh
router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret) as { id: string };
    const tokens = generateTokens(decoded.id);
    res.json(tokens);
  } catch {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});

// GET /api/v1/auth/me
router.get('/me', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }
    res.json(user);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/v1/auth/profile — update profile
router.put('/profile', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const allowed = ['display_name', 'avatar', 'age', 'gender', 'timezone', 'language', 'reminder_enabled', 'reminder_time'];
    const updates: any = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    const user = await User.findByIdAndUpdate(req.userId, updates, { new: true });
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }
    res.json(user);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/auth/change-password
router.post('/change-password', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { current_password, new_password } = req.body;
    const user = await User.findById(req.userId).select('+password_hash');
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }
    if (!(await user.comparePassword(current_password))) {
      res.status(400).json({ error: 'Current password is incorrect' }); return;
    }
    user.password_hash = new_password;
    await user.save();
    res.json({ message: 'Password changed successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/auth/forgot-password — generate reset token (simplified)
router.post('/forgot-password', async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) { res.json({ message: 'If email exists, reset link sent' }); return; }
    const resetToken = crypto.randomBytes(32).toString('hex');
    // In production: store token in DB with expiry, send email
    // For now: return token directly (dev mode)
    res.json({ message: 'If email exists, reset link sent', _dev_token: resetToken });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/v1/auth/export — export all user data (GDPR)
router.get('/export', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { Checkin, Insight, Goal, Notification, Streak } = await import('../models');
    const user = await User.findById(req.userId);
    const checkins = await Checkin.find({ user_id: req.userId });
    const insights = await Insight.find({ user_id: req.userId });
    const goals = await Goal.find({ user_id: req.userId });
    const notifications = await Notification.find({ user_id: req.userId });
    const streak = await Streak.findOne({ user_id: req.userId });
    res.json({ user, checkins, insights, goals, notifications, streak });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/v1/auth/delete-account — hard delete all data
router.delete('/delete-account', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { Checkin, Insight, Goal, Notification, Streak } = await import('../models');
    await Promise.all([
      Checkin.deleteMany({ user_id: req.userId }),
      Insight.deleteMany({ user_id: req.userId }),
      Goal.deleteMany({ user_id: req.userId }),
      Notification.deleteMany({ user_id: req.userId }),
      Streak.deleteMany({ user_id: req.userId }),
      User.findByIdAndDelete(req.userId),
    ]);
    res.json({ message: 'Account and all data deleted permanently' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
