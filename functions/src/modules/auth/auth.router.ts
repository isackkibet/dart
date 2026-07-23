import { Router } from "express";
import { getAuth } from "firebase-admin/auth";

import { requireAuth } from "../../core/http/requireAuth";
import { requireAdmin } from "../../core/http/requireAdmin";
import { fail, ok } from "../../core/http/respond";
import { AssignClaimsSchema } from "./auth.schema";

export const authRouter = Router();

authRouter.get("/me", requireAuth, async (req, res) => {
  return ok(res, {
    user: req.user,
  });
});

authRouter.post("/assign-claims", requireAuth, requireAdmin, async (req, res) => {
  const parsed = AssignClaimsSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(
      res,
      400,
      "invalid_claims_payload",
      "Invalid custom claims payload.",
      parsed.error.flatten(),
    );
  }

  const input = parsed.data;
  const claims = {
    role: input.role,
    creator: input.creator ?? input.role === "creator",
    admin: input.admin ?? input.role === "admin",
    moderator: input.role === "moderator",
    operator: input.role === "operator",
    approver: input.role === "approver",
    finance: input.role === "finance",
  };

  await getAuth().setCustomUserClaims(input.uid, claims);
  return ok(res, {
    uid: input.uid,
    claims,
    message: "Custom claims assigned. User must refresh token or re-login.",
  });
});
