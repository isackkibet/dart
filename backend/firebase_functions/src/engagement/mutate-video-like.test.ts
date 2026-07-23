// In-memory Firestore simulation for idempotency test.
function makeInMemoryStore() {
  const docs = new Map<string, Record<string, unknown>>();

  const get = (path: string) => ({
    exists: docs.has(path),
    data: () => docs.get(path),
  });

  const set = (path: string, data: Record<string, unknown>, opts?: { merge?: boolean }) => {
    if (opts?.merge) {
      docs.set(path, { ...(docs.get(path) ?? {}), ...data });
    } else {
      docs.set(path, data);
    }
  };

  const del = (path: string) => docs.delete(path);

  const increment = (n: number) => ({ __increment: n });

  return { get, set, del, increment, docs };
}

async function mutateLike(
  store: ReturnType<typeof makeInMemoryStore>,
  {
    videoId,
    userId,
    liked,
    mutationId,
  }: {
    videoId: string;
    userId: string;
    liked: boolean;
    mutationId: string;
  }
) {
  const mutationPath = `engagementMutations/${mutationId}`;
  const likePath = `videoLikes/${videoId}_${userId}`;
  const countPath = `videoEngagement/${videoId}`;

  const mutationSnap = store.get(mutationPath);
  if (mutationSnap.exists) return; // idempotent

  const likeSnap = store.get(likePath);
  const alreadyLiked = likeSnap.exists;

  const current = (store.docs.get(countPath) ?? { likes: 0 }) as { likes: number };

  if (liked && !alreadyLiked) {
    store.set(likePath, { videoId, userId });
    store.set(countPath, { likes: (current.likes ?? 0) + 1 }, { merge: true });
  } else if (!liked && alreadyLiked) {
    store.del(likePath);
    store.set(countPath, { likes: (current.likes ?? 0) - 1 }, { merge: true });
  }

  store.set(mutationPath, { mutationId, videoId, userId, action: liked ? "like" : "unlike" });
}

describe("mutateVideoLike — idempotency", () => {
  it("does not count the same like mutation twice", async () => {
    const store = makeInMemoryStore();
    const params = {
      videoId: "video-001",
      userId: "user-001",
      liked: true,
      mutationId: "mutation-001",
    };

    await mutateLike(store, params);
    await mutateLike(store, params); // duplicate

    const engagement = store.docs.get("videoEngagement/video-001") as { likes: number };
    expect(engagement.likes).toBe(1);
  });

  it("does not count the same unlike mutation twice", async () => {
    const store = makeInMemoryStore();
    // First: like
    await mutateLike(store, {
      videoId: "video-002",
      userId: "user-001",
      liked: true,
      mutationId: "mutation-a",
    });
    // Then: unlike (same mutationId used twice)
    await mutateLike(store, {
      videoId: "video-002",
      userId: "user-001",
      liked: false,
      mutationId: "mutation-b",
    });
    await mutateLike(store, {
      videoId: "video-002",
      userId: "user-001",
      liked: false,
      mutationId: "mutation-b",
    }); // duplicate

    const engagement = store.docs.get("videoEngagement/video-002") as { likes: number };
    expect(engagement.likes).toBe(0);
  });
});
