import mongoose, { Document, Schema } from 'mongoose';

export interface ICheckin extends Document {
  user_id: mongoose.Types.ObjectId;
  mood_score: number;
  energy_level: 'low' | 'normal' | 'high';
  text_note?: string;
  tags: string[];
  created_at: Date;
}

const checkinSchema = new Schema<ICheckin>({
  user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  mood_score: { type: Number, required: true, min: 1, max: 5 },
  energy_level: { type: String, enum: ['low', 'normal', 'high'], required: true },
  text_note: { type: String, maxlength: 500 },
  tags: [{ type: String, trim: true }],
  created_at: { type: Date, default: Date.now },
});

checkinSchema.index({ user_id: 1, created_at: -1 });

export const Checkin = mongoose.model<ICheckin>('Checkin', checkinSchema);
