import mongoose, { Document, Schema } from 'mongoose';

export interface IInsight extends Document {
  user_id: mongoose.Types.ObjectId;
  period: '7d' | '30d' | '60d' | '90d';
  bullets: string[];
  meta: {
    avg_mood: number;
    mood_trend: 'up' | 'down' | 'stable';
    stress_level: 'low' | 'medium' | 'high';
    top_topics: string[];
    positive_score: number;
  };
  created_at: Date;
}

const insightSchema = new Schema<IInsight>({
  user_id: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  period: { type: String, enum: ['7d', '30d', '60d', '90d'], required: true },
  bullets: [{ type: String }],
  meta: {
    avg_mood: { type: Number },
    mood_trend: { type: String, enum: ['up', 'down', 'stable'] },
    stress_level: { type: String, enum: ['low', 'medium', 'high'] },
    top_topics: [{ type: String }],
    positive_score: { type: Number },
  },
  created_at: { type: Date, default: Date.now },
});

insightSchema.index({ user_id: 1, created_at: -1 });

export const Insight = mongoose.model<IInsight>('Insight', insightSchema);
