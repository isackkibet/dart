import { assertCreatorLibraryAccess } from "./creator-library-access";
import type { CreatorLibraryCategory } from "./creator-library.types";

describe("assertCreatorLibraryAccess", () => {
  // Owner can access everything
  it("allows owner to access owner-only categories", () => {
    const ownerOnlyCategories: CreatorLibraryCategory[] = [
      "drafts",
      "privateVideos",
      "scheduled",
      "pendingReview",
      "rejected",
      "saved",
      "liked",
      "shared",
      "viewHistory",
      "blocked",
      "archived",
    ];
    for (const category of ownerOnlyCategories) {
      expect(() =>
        assertCreatorLibraryAccess({
          requesterId: "creator-001",
          creatorId: "creator-001",
          category,
        })
      ).not.toThrow();
    }
  });

  // Visitor can access public categories
  it("allows visitor to access public categories", () => {
    const publicCategories: CreatorLibraryCategory[] = [
      "publicVideos",
      "pinned",
      "popular",
      "series",
      "liveReplays",
    ];
    for (const category of publicCategories) {
      expect(() =>
        assertCreatorLibraryAccess({
          requesterId: "visitor-001",
          creatorId: "creator-001",
          category,
        })
      ).not.toThrow();
    }
  });

  // Visitor blocked from owner-only categories
  it("throws PERMISSION_DENIED when visitor requests drafts", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: "visitor-001",
        creatorId: "creator-001",
        category: "drafts",
      })
    ).toThrow("PERMISSION_DENIED");
  });

  it("throws PERMISSION_DENIED when visitor requests privateVideos", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: "visitor-001",
        creatorId: "creator-001",
        category: "privateVideos",
      })
    ).toThrow("PERMISSION_DENIED");
  });

  it("throws PERMISSION_DENIED when visitor requests viewHistory", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: "visitor-001",
        creatorId: "creator-001",
        category: "viewHistory",
      })
    ).toThrow("PERMISSION_DENIED");
  });

  it("throws PERMISSION_DENIED when visitor requests liked", () => {
    expect(() =>
      assertCreatorLibraryAccess({
        requesterId: "visitor-001",
        creatorId: "creator-001",
        category: "liked",
      })
    ).toThrow("PERMISSION_DENIED");
  });
});
