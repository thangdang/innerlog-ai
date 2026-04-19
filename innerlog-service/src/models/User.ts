import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';

export interface IUser extends Document {
  email: string;
  password_hash: string;
  display_name?: string;
  avatar?: string;
  age?: number;
  gender?: string;
  timezone: string;
  language: string;
  plan: 'free' | 'premium';
  role: 'user' | 'admin';
  reminder_enabled: boolean;
  reminder_time?: string;
  theme: 'light' | 'dark' | 'system';
  notify_coach: boolean;
  notify_reminder: boolean;
  notify_insight: boolean;
  created_at: Date;
  comparePassword(password: string): Promise<boolean>;
}

const userSchema = new Schema<IUser>({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password_hash: { type: String, required: true },
  display_name: { type: String, trim: true },
  avatar: { type: String },
  age: { type: Number },
  gender: { type: String, enum: ['male', 'female', 'other', null] },
  timezone: { type: String, default: 'Asia/Ho_Chi_Minh' },
  language: { type: String, default: 'vi' },
  plan: { type: String, enum: ['free', 'premium'], default: 'free' },
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  reminder_enabled: { type: Boolean, default: true },
  reminder_time: { type: String, default: '21:00' },
  theme: { type: String, enum: ['light', 'dark', 'system'], default: 'system' },
  notify_coach: { type: Boolean, default: true },
  notify_reminder: { type: Boolean, default: true },
  notify_insight: { type: Boolean, default: true },
  created_at: { type: Date, default: Date.now },
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('password_hash')) return next();
  this.password_hash = await bcrypt.hash(this.password_hash, 12);
  next();
});

userSchema.methods.comparePassword = async function (password: string): Promise<boolean> {
  return bcrypt.compare(password, this.password_hash);
};

userSchema.set('toJSON', {
  transform: (_doc, ret) => {
    delete ret.password_hash;
    delete ret.__v;
    return ret;
  },
});

export const User = mongoose.model<IUser>('User', userSchema);
