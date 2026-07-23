import { NextFunction, Response } from "express";

import { AuthenticatedRequest } from "./requireAuth";
import { fail } from "./respond";

export function requireAdmin(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): void {
  if (req.user?.admin !== true && req.user?.role !== "admin") {
    fail(res, 403, "admin_required", "Admin access is required.");
    return;
  }
  next();
}
