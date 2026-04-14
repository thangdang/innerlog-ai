import mongoose, { Document, Schema } from 'mongoose';

export interface IStreak extends Document {
  user_id: mongoose.Types.ObjectId;
  current_streak: number;
  longest_streak: number;
  last_checkin_date: string; // YYYY-MM-DD
  total_checkins: number;
  updated_at: Date;
}

const streakSchema = new Schema<IStreak>({
  user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  current_streak: { type: Number, default: 0 },
  longest_streak: { type: Number, default: 0 },
  last_checkin_date: { type: String, default: '' },
  total_checkins: { type: Number, default: 0 },
  updated_at: { type: Date, default: Date.now },
});

export const Streak = mongoose.model<IStreak>('Streak', streakSchema);
