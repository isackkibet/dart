import { Request, Response, NextFunction } from "express";
import { getAuth } from "firebase-admin/auth";
import { fail } from "./respond";

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    role?: string;
    admin?: boolean;
  };
}

declare global {
  namespace Express {
    interface Request {
      user?: {
        uid: string;
        email?: string;
        role?: string;
        admin?: boolean;
      };
    }
  }
}

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
) {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) {
      fail(res, 401, "missing_auth", "Missing bearer token.");
      return;
    }
    const token = header.replace("Bearer ", "").trim();
    const decoded = await getAuth().verifyIdToken(token, true);
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      role: typeof decoded.role === "string" ? decoded.role : undefined,
      admin: decoded.admin === true,
    };
    next();
  } catch (error) {
    fail(res, 401, "invalid_auth", "Invalid or expired token.", error);
  }
}
