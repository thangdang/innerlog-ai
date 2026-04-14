import mongoose, { Document, Schema } from 'mongoose';

export interface INotification extends Document {
  user_id: mongoose.Types.ObjectId;
  type: 'coach' | 'reminder' | 'insight' | 'streak' | 'system';
  title: string;
  message: string;
  read: boolean;
  created_at: Date;
}

const notificationSchema = new Schema<INotification>({
  user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  type: { type: String, enum: ['coach', 'reminder', 'insight', 'streak', 'system'], required: true },
  title: { type: String, required: true },
  message: { type: String, required: true },
  read: { type: Boolean, default: false },
  created_at: { type: Date, default: Date.now },
});

notificationSchema.index({ user_id: 1, read: 1, created_at: -1 });

export const Notification = mongoose.model<INotification>('Notification', notificationSchema);
