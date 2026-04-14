import mongoose, { Document, Schema } from 'mongoose';

export interface IGoalTask {
  title: string;
  done: boolean;
}

export interface IGoal extends Document {
  user_id: mongoose.Types.ObjectId;
  title: string;
  category: 'study' | 'work' | 'health' | 'finance' | 'other';
  tasks: IGoalTask[];
  progress: number;
  status: 'active' | 'completed' | 'abandoned';
  created_at: Date;
  updated_at: Date;
}

const goalSchema = new Schema<IGoal>({
  user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true, maxlength: 200 },
  category: { type: String, enum: ['study', 'work', 'health', 'finance', 'other'], default: 'other' },
  tasks: [{
    title: { type: String, required: true },
    done: { type: Boolean, default: false },
  }],
  progress: { type: Number, default: 0, min: 0, max: 100 },
  status: { type: String, enum: ['active', 'completed', 'abandoned'], default: 'active' },
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now },
});

goalSchema.index({ user_id: 1, status: 1 });

export const Goal = mongoose.model<IGoal>('Goal', goalSchema);
