import { assertCreatorLibraryAccess } from "./assert-creator-library-access";

describe("assertCreatorLibraryAccess — PROFILE-SEC-01", () => {
  const creatorId = "creator-001";
  const viewerId = "viewer-999";

  it("allows owner to access any category", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: creatorId,
        creatorId,
        category: "drafts",
      })
    ).not.toThrow();
  });

  it("allows any user to access publicVideos", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: viewerId,
        creatorId,
        category: "publicVideos",
      })
    ).not.toThrow();
  });

  it("blocks non-owner from drafts", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: viewerId,
        creatorId,
        category: "drafts",
      })
    ).toThrow("PERMISSION_DENIED");
  });

  it("blocks non-owner from privateVideos", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: viewerId,
        creatorId,
        category: "privateVideos",
      })
    ).toThrow("PERMISSION_DENIED");
  });

  it("blocks non-owner from viewHistory", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: viewerId,
        creatorId,
        category: "viewHistory",
      })
    ).toThrow("PERMISSION_DENIED");
  });

  it("blocks non-owner from liked", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: viewerId,
        creatorId,
        category: "liked",
      })
    ).toThrow("PERMISSION_DENIED");
  });
});
