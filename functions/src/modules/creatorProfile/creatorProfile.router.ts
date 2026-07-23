import { Router } from "express";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import { requireAuth } from "../../core/http/requireAuth";
import { fail, ok } from "../../core/http/respond";
import { UpsertCreatorProfileSchema } from "./creatorProfile.schema";

export const creatorProfileRouter = Router();

const db = getFirestore();

creatorProfileRouter.get("/me", requireAuth, async (req, res) => {
  const uid = req.user?.uid;
  if (!uid) {
    return fail(res, 401, "missing_user", "Missing authenticated user.");
  }

  const snapshot = await db
    .collection("creatorProfiles")
    .where("uid", "==", uid)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return ok(res, {
      profile: null,
    });
  }

  const doc = snapshot.docs[0];
  return ok(res, {
    profile: {
      id: doc.id,
      ...doc.data(),
    },
  });
});

creatorProfileRouter.post("/me", requireAuth, async (req, res) => {
  const uid = req.user?.uid;
  if (!uid) {
    return fail(res, 401, "missing_user", "Missing authenticated user.");
  }

  const parsed = UpsertCreatorProfileSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(
      res,
      400,
      "invalid_creator_profile_payload",
      "Invalid creator profile payload.",
      parsed.error.flatten(),
    );
  }

  const input = parsed.data;
  const existing = await db
    .collection("creatorProfiles")
    .where("uid", "==", uid)
    .limit(1)
    .get();

  const payload = {
    uid,
    displayName: input.displayName,
    handle: input.handle.toLowerCase(),
    category: input.category ?? "",
    bio: input.bio ?? "",
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: uid,
    status: "active",
  };

  if (existing.empty) {
    const doc = db.collection("creatorProfiles").doc();
    await doc.set({
      ...payload,
      verificationStatus: "pending",
      monetisationEnabled: false,
      riskScore: 0,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: uid,
    });
    return ok(
      res,
      {
        id: doc.id,
        ...payload,
      },
      201,
    );
  }

  const doc = existing.docs[0];
  await doc.ref.update(payload);
  return ok(res, {
    id: doc.id,
    ...payload,
  });
});
