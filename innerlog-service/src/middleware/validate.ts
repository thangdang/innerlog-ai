import { Request, Response, NextFunction } from 'express';
import { validationResult } from 'express-validator';

/**
 * Express middleware that checks express-validator results.
 * Returns 400 with formatted errors if validation fails.
 */
export function validate(req: Request, res: Response, next: NextFunction): void {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({ errors: errors.array() });
    return;
  }
  next();
}
