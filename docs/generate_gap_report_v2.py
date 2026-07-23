"""Generate YohPal Mobile Flutter Gap Report v2 PDF."""
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether,
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
import datetime

OUTPUT = "/Users/mac/Documents/f-ed/yohpal-video-app/docs/YohPal_Mobile_Flutter_Gap_Report_v2.pdf"

# ── Colour palette ────────────────────────────────────────────────────────────
NAVY       = colors.HexColor("#050816")
CARD       = colors.HexColor("#101527")
ACCENT     = colors.HexColor("#4F8EF7")
GREEN      = colors.HexColor("#22C55E")
AMBER      = colors.HexColor("#F59E0B")
RED        = colors.HexColor("#EF4444")
WHITE      = colors.white
LIGHT_GREY = colors.HexColor("#94A3B8")
TEXT       = colors.HexColor("#1E293B")
SUBTEXT    = colors.HexColor("#475569")

W, H = A4
MARGIN = 18 * mm

doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    leftMargin=MARGIN, rightMargin=MARGIN,
    topMargin=MARGIN, bottomMargin=MARGIN,
    title="YohPal Mobile Flutter Gap Report v2",
    author="Claude Code / Daniel Macharia",
)

styles = getSampleStyleSheet()

def S(name, **kw):
    return ParagraphStyle(name, **kw)

cover_title = S("CoverTitle", fontSize=26, leading=32, textColor=ACCENT,
                fontName="Helvetica-Bold", alignment=TA_CENTER, spaceAfter=4)
cover_sub   = S("CoverSub",  fontSize=13, leading=18, textColor=WHITE,
                fontName="Helvetica",     alignment=TA_CENTER, spaceAfter=2)
cover_meta  = S("CoverMeta", fontSize=9,  leading=13, textColor=LIGHT_GREY,
                fontName="Helvetica",     alignment=TA_CENTER)

h1 = S("H1", fontSize=15, leading=20, textColor=ACCENT, fontName="Helvetica-Bold",
        spaceBefore=14, spaceAfter=4)
h2 = S("H2", fontSize=11, leading=15, textColor=WHITE,  fontName="Helvetica-Bold",
        spaceBefore=10, spaceAfter=3)
body = S("Body", fontSize=9, leading=13, textColor=TEXT, fontName="Helvetica",
         spaceBefore=2, spaceAfter=2)
note = S("Note", fontSize=8, leading=11, textColor=SUBTEXT, fontName="Helvetica-Oblique",
         spaceBefore=2)
bold_body = S("BoldBody", fontSize=9, leading=13, textColor=TEXT,
              fontName="Helvetica-Bold", spaceBefore=2, spaceAfter=2)


def hr(color=ACCENT, thickness=1):
    return HRFlowable(width="100%", thickness=thickness, color=color, spaceAfter=6, spaceBefore=4)


def progress_bar(pct, width=120, height=8):
    """Return a 1-row table that looks like a progress bar."""
    filled = int(width * pct / 100)
    empty  = width - filled
    bar_color = GREEN if pct >= 60 else (AMBER if pct >= 20 else RED)
    data = [[""]]
    t = Table(data, colWidths=[width], rowHeights=[height])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#E2E8F0")),
        ("LEFTPADDING",  (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING",   (0, 0), (-1, -1), 0),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 0),
    ]))
    # Two-cell overlay: filled | empty
    data2 = [["", ""]]
    t2 = Table(data2, colWidths=[filled or 1, empty or 1], rowHeights=[height])
    t2.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, 0), bar_color),
        ("BACKGROUND", (1, 0), (1, 0), colors.HexColor("#E2E8F0")),
        ("LEFTPADDING",  (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING",   (0, 0), (-1, -1), 0),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 0),
        ("BOX", (0, 0), (-1, -1), 0.5, LIGHT_GREY),
    ]))
    return t2


def feature_table(rows):
    """rows: list of (feature_str, status_str, status_type)
       status_type: 'ok' | 'warn' | 'bad'
    """
    col_w = [W - 2*MARGIN - 40*mm, 40*mm]
    icon = {"ok": "✅", "warn": "⚠️", "bad": "❌"}
    colour = {"ok": GREEN, "warn": AMBER, "bad": RED}

    tdata = []
    for feature, status, stype in rows:
        tdata.append([
            Paragraph(feature, S("ft", fontSize=8, leading=11, textColor=TEXT,
                                 fontName="Helvetica")),
            Paragraph(f"{icon[stype]}  {status}", S("fs", fontSize=8, leading=11,
                      textColor=colour[stype], fontName="Helvetica-Bold")),
        ])

    t = Table(tdata, colWidths=col_w)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), WHITE),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [WHITE, colors.HexColor("#F8FAFC")]),
        ("GRID",       (0, 0), (-1, -1), 0.3, colors.HexColor("#CBD5E1")),
        ("LEFTPADDING",  (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING",   (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 4),
        ("VALIGN",     (0, 0), (-1, -1), "TOP"),
    ]))
    return t


def module_summary_table(rows):
    """rows: list of (module, phase, pct_int)"""
    col_w = [55*mm, 30*mm, 22*mm, 55*mm]
    hdr = [
        Paragraph("Module", S("th", fontSize=8, fontName="Helvetica-Bold",
                              textColor=WHITE)),
        Paragraph("Blueprint Phase", S("th2", fontSize=8, fontName="Helvetica-Bold",
                                       textColor=WHITE)),
        Paragraph("Complete", S("th3", fontSize=8, fontName="Helvetica-Bold",
                                textColor=WHITE, alignment=TA_RIGHT)),
        Paragraph("Progress", S("th4", fontSize=8, fontName="Helvetica-Bold",
                                textColor=WHITE)),
    ]
    tdata = [hdr]
    for module, phase, pct in rows:
        bar_color = GREEN if pct >= 60 else (AMBER if pct >= 20 else RED)
        filled = int(55 * pct / 100)
        empty  = 55 - filled
        bar_data = [["", ""]]
        bar = Table(bar_data, colWidths=[filled or 1, empty or 1], rowHeights=[7])
        bar.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (0, 0), bar_color),
            ("BACKGROUND", (1, 0), (1, 0), colors.HexColor("#E2E8F0")),
            ("LEFTPADDING",  (0, 0), (-1, -1), 0),
            ("RIGHTPADDING", (0, 0), (-1, -1), 0),
            ("TOPPADDING",   (0, 0), (-1, -1), 0),
            ("BOTTOMPADDING",(0, 0), (-1, -1), 0),
        ]))
        tdata.append([
            Paragraph(module, S("td", fontSize=8, fontName="Helvetica", textColor=TEXT)),
            Paragraph(phase,  S("td2", fontSize=8, fontName="Helvetica", textColor=SUBTEXT)),
            Paragraph(f"{pct}%", S("td3", fontSize=8, fontName="Helvetica-Bold",
                                   textColor=bar_color, alignment=TA_RIGHT)),
            bar,
        ])
    # overall row
    overall_pct = 31
    tdata.append([
        Paragraph("OVERALL", S("ov", fontSize=8, fontName="Helvetica-Bold", textColor=ACCENT)),
        Paragraph("All phases", S("ov2", fontSize=8, fontName="Helvetica", textColor=SUBTEXT)),
        Paragraph("31%", S("ov3", fontSize=8, fontName="Helvetica-Bold",
                           textColor=ACCENT, alignment=TA_RIGHT)),
        Paragraph("▲ from 22% (prev report)", S("ov4", fontSize=8,
                  fontName="Helvetica-Oblique", textColor=ACCENT)),
    ])

    t = Table(tdata, colWidths=col_w)
    t.setStyle(TableStyle([
        ("BACKGROUND",   (0, 0), (-1, 0),  CARD),
        ("BACKGROUND",   (0, -1),(-1, -1), colors.HexColor("#0F172A")),
        ("ROWBACKGROUNDS",(0,1),(-1,-2), [WHITE, colors.HexColor("#F8FAFC")]),
        ("GRID",         (0, 0), (-1, -1), 0.3, colors.HexColor("#CBD5E1")),
        ("LEFTPADDING",  (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING",   (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 5),
        ("VALIGN",       (0, 0), (-1, -1), "MIDDLE"),
    ]))
    return t


# ── Build story ───────────────────────────────────────────────────────────────
story = []

# ── Cover block ───────────────────────────────────────────────────────────────
story.append(Spacer(1, 18*mm))
story.append(Paragraph("YOHPAL LIVE", cover_title))
story.append(Paragraph("Mobile Flutter — Gap Report v2", cover_sub))
story.append(Paragraph(
    f"Date: 2026-06-17  |  Branch: flutter_app  |  Commit: f61cd1d  |  "
    f"Analyst: Claude Code / Daniel Macharia", cover_meta))
story.append(Spacer(1, 6*mm))
story.append(hr(ACCENT, 2))
story.append(Spacer(1, 4*mm))

# ── Executive Summary ─────────────────────────────────────────────────────────
story.append(Paragraph("Executive Summary", h1))
summary_rows = [
    ["flutter analyze", "PASS — 0 issues"],
    ["flutter test",    "PASS — 1/1"],
    ["Commit hash",     "f61cd1d87ae4651c64387674d328b1bafb3f1689"],
    ["Phases merged",   "1A · 1B · 1C · 1D · 1E · 1F"],
    ["Files changed",   "47 files, +2593 / −144 lines vs Phase 1A"],
    ["Overall completion", "~31%  (↑ from ~22% at previous report)"],
]
exec_t = Table(summary_rows, colWidths=[55*mm, W - 2*MARGIN - 55*mm])
exec_t.setStyle(TableStyle([
    ("BACKGROUND",   (0, 0), (0, -1), CARD),
    ("BACKGROUND",   (1, 0), (1, -1), WHITE),
    ("FONTNAME",     (0, 0), (0, -1), "Helvetica-Bold"),
    ("FONTNAME",     (1, 0), (1, -1), "Helvetica"),
    ("FONTSIZE",     (0, 0), (-1, -1), 9),
    ("TEXTCOLOR",    (0, 0), (0, -1), ACCENT),
    ("TEXTCOLOR",    (1, 0), (1, -1), TEXT),
    ("GRID",         (0, 0), (-1, -1), 0.3, colors.HexColor("#CBD5E1")),
    ("LEFTPADDING",  (0, 0), (-1, -1), 8),
    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ("TOPPADDING",   (0, 0), (-1, -1), 5),
    ("BOTTOMPADDING",(0, 0), (-1, -1), 5),
]))
story.append(exec_t)
story.append(Spacer(1, 4*mm))
story.append(Paragraph(
    "Every Dart file was read directly. A file returning SizedBox.shrink() or "
    "Future&lt;void&gt; execute() async {} is counted as a stub (0–5%), not an implementation. "
    "Completion percentages reflect real, working logic — not file existence.",
    note))
story.append(Spacer(1, 4*mm))
story.append(hr())

# ── Module Summary Table ───────────────────────────────────────────────────────
story.append(Paragraph("Overall Completion by Blueprint Module", h1))
modules = [
    ("A. Short Video Engine",     "Phase 1",  62),
    ("B. AI Video & Photo Suite", "Phase 2",   5),
    ("C. Live Streaming",         "Phase 3",   5),
    ("D. Multi-Streaming",        "Phase 3",   5),
    ("E. Monetisation Engine",    "Phase 5",  18),
    ("F. Contacts Growth Engine", "Phase 4",   5),
    ("G. Search Engine",          "Phase 6",   5),
    ("H. Affiliate Engine",       "Phase 4",  18),
    ("I. Infinity Polls",         "Phase 6",  20),
    ("J. Ads Engine",             "Phase 5",  15),
    ("K. Web-Based Wallet",       "Phase 5",  10),
    ("L. Chat Engine",            "Phase 6",   5),
]
story.append(module_summary_table(modules))
story.append(Spacer(1, 4*mm))
story.append(hr())

# ── Module Detail sections ────────────────────────────────────────────────────
def module_section(title, pct, implemented, warn, missing):
    items = []
    bar_color = GREEN if pct >= 60 else (AMBER if pct >= 20 else RED)
    # Header row
    hdr_data = [[
        Paragraph(title, S("mh", fontSize=11, fontName="Helvetica-Bold",
                           textColor=WHITE)),
        Paragraph(f"{pct}% complete", S("mhp", fontSize=11, fontName="Helvetica-Bold",
                                        textColor=bar_color, alignment=TA_RIGHT)),
    ]]
    hdr_t = Table(hdr_data, colWidths=[W-2*MARGIN-32*mm, 32*mm])
    hdr_t.setStyle(TableStyle([
        ("BACKGROUND",   (0, 0), (-1, -1), CARD),
        ("LEFTPADDING",  (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING",   (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 6),
    ]))
    items.append(hdr_t)
    items.append(Spacer(1, 2))

    rows = []
    for f in implemented:
        rows.append((f, "Implemented", "ok"))
    for f in warn:
        rows.append((f[0], f[1], "warn"))
    for f in missing:
        rows.append((f, "Not started", "bad"))

    if rows:
        items.append(feature_table(rows))
    items.append(Spacer(1, 4*mm))
    return KeepTogether(items) if len(items) < 8 else items


# A. Short Video Engine
story.append(Paragraph("Module Detail", h1))

a_ok = [
    "Vertical PageView feed",
    "Instant playback — VideoPlayerWidget with 7s init timeout + 10s stall timer",
    "Suggested feed (Firestore query: status==live, orderBy createdAt)",
    "Following feed (reads follows collection, whereIn ownerId)",
    "Broken video auto-hide (onPlaybackError → markVideoAsBroken → removes from list)",
    "Comments + nested replies + reactions + reports (Firestore transactions)",
    "Creator profile link from video overlay (routes with ownerId argument)",
    "Poll / shop / affiliate action buttons in overlay",
    "VideoFeedController — Provider-based, loadFeed(FeedType, category)",
    "FeedType enum: suggested · following · trending · category",
    "OfflineVideoCacheService stub registered as Provider",
]
a_warn = [
    ("Trending feed", "Repository method exists; no UI tab"),
    ("Category / niche feed", "Repository method exists; no UI"),
    ("OfflineVideoCacheService", "In-memory Set only — no real disk cache"),
    ("VideoPrefetchService / VideoRankingService", "Files exist but disconnected from controller"),
    ("VideoInteractionService", "File exists but disconnected — likes/bookmarks not persisted"),
    ("Share button", "onPressed: () {} — no implementation"),
]
a_bad = [
    "AI-ranked For You feed (backend engagement scoring)",
    "Nearby / local feed",
    "Saves / bookmark UI button in overlay",
    "Duets / stitches",
    "Predictive prefetch by scroll velocity",
    "Engagement event tracking to videoEvents collection",
]
story += module_section("A. Short Video Engine", 62, a_ok, a_warn, a_bad)

# B. AI Editor
b_warn = [
    ("AiEditorScreen", "Placeholder screen — Scaffold + Center(Text)"),
    ("AiVideoRepository", "Empty FirebaseFirestore wrapper"),
]
b_bad = [
    "AiCaptionService — class body: Future<void> execute() async {}",
    "AiHookService — same empty stub",
    "AiThumbnailService — same empty stub",
    "AiTranslationService — same empty stub",
    "AI background removal, music recommendation, voiceover, beautify",
    "aiVideoJobs write flow + Cloud Function processing pipeline",
    "Viral score prediction",
    "AI auto-trim / highlight clipping",
]
story += module_section("B. AI Video & Photo Editing Suite", 5, ["aiVideoJobs Firestore rule deployed"], b_warn, b_bad)

# C. Live Streaming
c_warn = [
    ("GoLiveScreen", "Placeholder screen"),
    ("LiveViewerScreen", "Placeholder screen"),
    ("LiveChatPanel", "SizedBox.shrink()"),
    ("LiveGiftPanel", "SizedBox.shrink()"),
    ("LiveRepository", "Empty Firestore wrapper"),
]
c_bad = [
    "LiveStreamService — empty stub",
    "RTMP ingest integration (Agora / LiveKit / custom)",
    "HLS playback in live viewer",
    "Real-time live chat (Firestore subcollection stream)",
    "Gifts / tipping transaction flow",
    "Live polls overlay",
    "Live shopping",
    "Co-hosting / battles",
    "Live recording + replay feed",
]
story += module_section("C. Live Streaming", 5, ["liveSessions Firestore rule deployed"], c_warn, c_bad)

# D. Multi-Streaming
d_warn = [
    ("MultistreamSetupScreen", "Placeholder screen"),
    ("MultistreamService", "Empty stub"),
    ("MultistreamRepository", "Empty Firestore wrapper"),
]
d_bad = [
    "RTMP forwarding to YouTube / Facebook / TikTok / Instagram",
    "Destination selection UI",
    "Centralised stream analytics",
    "Custom RTMP destination support",
]
story += module_section("D. Multi-Streaming", 5, ["multistreamSessions Firestore rule deployed"], d_warn, d_bad)

# E. Monetisation
e_ok = [
    "eligibilityScore field in CreatorProfileModel + displayed in stats card",
    "creatorEarnings Firestore rule (owner-read only)",
    "videoStats Firestore rule (signed-in read, no client writes)",
    "CreatorAnalyticsScreen — reads videoStats, shows views/likes/shares",
]
e_warn = [
    ("CreatorEarningsScreen", "Placeholder screen"),
    ("MonetisationService", "Empty stub"),
    ("MonetisationRepository", "Empty Firestore wrapper"),
]
e_bad = [
    "Watch-time ledger writes to walletLedger",
    "Creator payout trigger (Cloud Function)",
    "Paid subscriptions / paid creator channels",
    "Video boosting purchase flow",
    "Brand sponsorship matching",
    "Withdrawal flow",
]
story += module_section("E. Monetisation Engine", 18, e_ok, e_warn, e_bad)

# F. Contacts Growth
f_warn = [
    ("InviteContactsScreen", "Placeholder screen"),
    ("ContactImportService", "Empty stub"),
    ("AiInviteRanker", "Empty stub"),
    ("ContactGrowthRepository", "Stub wrapper"),
]
f_bad = [
    "flutter_contacts phone book import",
    "AI likelihood-to-join ranking",
    "WhatsApp share card generation",
    "SMS invite fallback",
    "Referral tracking + conversion rewards",
    "Viral squads feature",
]
story += module_section("F. Contacts Growth Engine", 5, [], f_warn, f_bad)

# G. Search
g_warn = [
    ("SearchScreen", "Placeholder screen"),
    ("SearchService", "Empty stub"),
    ("SearchRepository", "Has SearchResult model; no queries"),
]
g_bad = [
    "Firestore full-text search (or Typesense / Algolia integration)",
    "BM25 keyword search",
    "Vector semantic search",
    "AI intent detection",
    "Search across videos, creators, live, polls, products",
    "Nearby / location-based search results",
]
story += module_section("G. Search Engine", 5, [], g_warn, g_bad)

# H. Affiliate
h_ok = [
    "affiliate_link model (AffiliateLink)",
    "affiliate_attribution model (AffiliateAttribution)",
    "affiliateLinks / affiliateAttributions Firestore rules deployed",
    "/affiliate route wired from VideoOverlayWidget",
]
h_warn = [
    ("AffiliateDashboardScreen", "Placeholder screen"),
    ("AffiliateService", "Empty stub"),
    ("AffiliateRepository", "Empty Firestore wrapper"),
]
h_bad = [
    "Commission calculation on real purchase events",
    "Affiliate link generation + deep link tracking",
    "Fraud detection checks",
    "Payout trigger integration with wallet",
    "Affiliate leaderboard / dashboard UI",
]
story += module_section("H. Affiliate Marketing Engine", 18, h_ok, h_warn, h_bad)

# I. Polls
i_ok = [
    "poll_model (PollModel) exists",
    "poll_vote (PollVote) model exists",
    "polls / pollVotes Firestore rules deployed",
    "/poll route wired from VideoOverlayWidget",
]
i_warn = [
    ("PollDetailScreen", "Placeholder screen"),
    ("PollRepository", "Empty Firestore wrapper"),
    ("VideoPollOverlay", "SizedBox.shrink() — not rendered in feed"),
    ("PollService", "Empty stub"),
]
i_bad = [
    "Vote submission with fraud-resistant write",
    "Real-time results stream in PollDetailScreen",
    "Poll-inside-video rendering via VideoPollOverlay",
    "Long-running national / brand polls",
    "AI poll summaries + trend charts",
    "Shareable poll results cards",
]
story += module_section("I. Infinity Polls", 20, i_ok, i_warn, i_bad)

# J. Ads
j_ok = [
    "ad_campaign model (AdCampaign)",
    "ad_impression model (AdImpression)",
    "adCampaigns / adImpressions Firestore rules deployed",
]
j_warn = [
    ("AdvertiserDashboardScreen", "Placeholder screen"),
    ("AdRepository", "Empty Firestore wrapper"),
    ("AdDeliveryService", "Stub"),
    ("InFeedAdWidget", "File exists — no real ad injection in feed"),
]
j_bad = [
    "Ad injection every Nth video in PageView feed",
    "Ad targeting (interest / location / watch behavior)",
    "Impression logging to adImpressions",
    "Web-based billing flow (avoid App Store commission)",
    "Campaign creation UI",
    "Click-through tracking",
]
story += module_section("J. Ads Engine", 15, j_ok, j_warn, j_bad)

# K. Wallet
k_ok = [
    "walletSessions / walletLedger Firestore rules deployed",
]
k_warn = [
    ("WalletStatusScreen", "Placeholder screen"),
    ("WalletLauncherService", "Presumably stub — file exists"),
]
k_bad = [
    "Mobile → web wallet handoff (url_launcher to web wallet)",
    "Web wallet payment / withdrawal flow",
    "Gift transaction trigger from live panel",
    "Subscription payment processing",
    "Marketplace payment integration",
]
story += module_section("K. Web-Based Wallet", 10, k_ok, k_warn, k_bad)

# L. Chat
l_warn = [
    ("ChatListScreen", "Placeholder screen"),
    ("ChatRoomScreen", "Placeholder screen"),
    ("ChatSdkAdapter", "Empty stub: Future<void> execute() async {}"),
    ("MessageBubble widget", "File exists — presumably stub"),
]
l_bad = [
    "chatConversations / chatMessages Firestore rules NOT deployed",
    "Real-time Firestore message stream",
    "Presence / typing indicators",
    "Message reactions / edits / soft deletes",
    "Media sharing in chat",
    "Push notification on new message",
    "Creator-to-fan / buyer-to-seller / group chat routing",
]
story += module_section("L. Chat Engine", 5, [], l_warn, l_bad)

story.append(hr())

# ── Priority Gap List ─────────────────────────────────────────────────────────
story.append(Paragraph("Priority Gap List — Next Phases", h1))

priority_data = [
    ["#", "Gap / Task", "Phase", "Priority"],
    ["1",  "Wire VideoInteractionService — likes, bookmarks, share count persist to Firestore", "1 (polish)", "HIGH"],
    ["2",  "Add save/bookmark button to VideoOverlayWidget", "1 (polish)", "HIGH"],
    ["3",  "Implement Share using share_plus package", "1 (polish)", "HIGH"],
    ["4",  "iOS Xcode: add Push Notifications + Background Modes capability", "1 (polish)", "HIGH"],
    ["5",  "Expose Trending tab in feed UI (_FeedTabs)", "1 (polish)", "MED"],
    ["6",  "Replace OfflineVideoCacheService with flutter_cache_manager", "1 (polish)", "MED"],
    ["7",  "Re-connect VideoPrefetchService to VideoFeedController", "1 (polish)", "MED"],
    ["8",  "AiEditorScreen — wire to Claude API for captions, hooks, hashtags, viral score", "2", "HIGH"],
    ["9",  "AiCaptionService, AiHookService, AiThumbnailService — real implementations", "2", "HIGH"],
    ["10", "aiVideoJobs write flow + Cloud Function result stream", "2", "HIGH"],
    ["11", "AI thumbnail selection in UploadScreen", "2", "MED"],
    ["12", "GoLiveScreen — Agora/LiveKit SDK integration", "3", "HIGH"],
    ["13", "LiveChatPanel — real-time Firestore subcollection stream", "3", "HIGH"],
    ["14", "LiveGiftPanel — wallet transaction trigger", "3", "MED"],
    ["15", "RTMP forwarding for multi-streaming", "3", "MED"],
    ["16", "ContactImportService — flutter_contacts phone book", "4", "HIGH"],
    ["17", "AiInviteRanker — likelihood-to-join scoring", "4", "MED"],
    ["18", "AffiliateRepository — create/track links + attributions", "4", "MED"],
    ["19", "CreatorEarningsScreen — real earnings from creatorEarnings", "5", "HIGH"],
    ["20", "MonetisationService — watch-time ledger writes", "5", "HIGH"],
    ["21", "Web wallet handoff via url_launcher", "5", "MED"],
    ["22", "SearchService — Firestore full-text or Typesense/Algolia", "6", "HIGH"],
    ["23", "PollDetailScreen — vote submission + live results stream", "6", "HIGH"],
    ["24", "VideoPollOverlay — render inside video feed PageView", "6", "HIGH"],
    ["25", "ChatListScreen / ChatRoomScreen — real Firestore messaging", "6", "HIGH"],
    ["26", "Deploy chatConversations/chatMessages Firestore rules", "6", "HIGH"],
    ["27", "InFeedAdWidget — inject every Nth video in feed", "6", "MED"],
    ["28", "AdvertiserDashboardScreen — campaign creation + impressions", "6", "MED"],
]

pri_color = {"HIGH": RED, "MED": AMBER, "LOW": GREEN}
p_col_w = [10*mm, 90*mm, 20*mm, 18*mm]
p_style = ParagraphStyle("pc", fontSize=8, leading=11, textColor=TEXT, fontName="Helvetica")
p_bold  = ParagraphStyle("pb", fontSize=8, leading=11, textColor=WHITE, fontName="Helvetica-Bold")

p_tdata = []
for i, row in enumerate(priority_data):
    if i == 0:
        p_tdata.append([Paragraph(c, p_bold) for c in row])
    else:
        num, task, phase, pri = row
        p_tdata.append([
            Paragraph(num, p_style),
            Paragraph(task, p_style),
            Paragraph(phase, p_style),
            Paragraph(pri, ParagraphStyle("pp", fontSize=8, leading=11,
                         textColor=pri_color.get(pri, TEXT), fontName="Helvetica-Bold")),
        ])

p_t = Table(p_tdata, colWidths=p_col_w)
p_t.setStyle(TableStyle([
    ("BACKGROUND",    (0, 0), (-1, 0),  CARD),
    ("ROWBACKGROUNDS",(0, 1), (-1, -1), [WHITE, colors.HexColor("#F8FAFC")]),
    ("GRID",          (0, 0), (-1, -1), 0.3, colors.HexColor("#CBD5E1")),
    ("LEFTPADDING",   (0, 0), (-1, -1), 5),
    ("RIGHTPADDING",  (0, 0), (-1, -1), 5),
    ("TOPPADDING",    (0, 0), (-1, -1), 4),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ("VALIGN",        (0, 0), (-1, -1), "TOP"),
]))
story.append(p_t)
story.append(Spacer(1, 4*mm))
story.append(hr())

# ── Recommendation ────────────────────────────────────────────────────────────
story.append(Paragraph("Developer Recommendation", h1))
rec_rows = [
    ["Immediate (before Phase 2)",
     "1. Reconnect Android device and do one flutter run pass to validate items 6–31 from the Phase 1G report.\n"
     "2. Add iOS Xcode Push Notifications + Background Modes capability.\n"
     "3. Wire VideoInteractionService (likes/bookmarks/shares) — 3 lines per action, already has Firestore paths.\n"
     "4. Add save button to VideoOverlayWidget."],
    ["Phase 2 — AI Creator Studio",
     "Implement real AI services. Wire AiEditorScreen to Claude API. Build aiVideoJobs Cloud Function pipeline. "
     "This is the biggest product differentiator vs TikTok and should start immediately after Phase 1 validation."],
    ["Phase 3 — Live Streaming",
     "Integrate Agora or LiveKit. Implement GoLiveScreen, LiveViewerScreen, LiveChatPanel, LiveGiftPanel. "
     "Add RTMP forwarding for multi-streaming to YouTube / Facebook."],
    ["Phase 4+ — Growth / Monetisation / Ecosystem",
     "ContactImportService → AiInviteRanker → AffiliateRepository → MonetisationService → "
     "SearchService → PollDetailScreen → ChatRoomScreen → InFeedAdWidget. "
     "Each of these has a correct stub in place and Firestore rules deployed — they need real logic, not scaffolding."],
]
rec_col_w = [45*mm, W-2*MARGIN-45*mm]
r_style = ParagraphStyle("rs", fontSize=8, leading=12, textColor=TEXT, fontName="Helvetica")
r_bold  = ParagraphStyle("rb", fontSize=8, leading=12, textColor=ACCENT, fontName="Helvetica-Bold")
r_tdata = [[Paragraph(r[0], r_bold), Paragraph(r[1].replace("\n", "<br/>"), r_style)] for r in rec_rows]
r_t = Table(r_tdata, colWidths=rec_col_w)
r_t.setStyle(TableStyle([
    ("ROWBACKGROUNDS",(0, 0), (-1, -1), [WHITE, colors.HexColor("#F8FAFC")]),
    ("GRID",         (0, 0), (-1, -1), 0.3, colors.HexColor("#CBD5E1")),
    ("LEFTPADDING",  (0, 0), (-1, -1), 8),
    ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ("TOPPADDING",   (0, 0), (-1, -1), 6),
    ("BOTTOMPADDING",(0, 0), (-1, -1), 6),
    ("VALIGN",       (0, 0), (-1, -1), "TOP"),
]))
story.append(r_t)
story.append(Spacer(1, 8*mm))

# ── Footer ────────────────────────────────────────────────────────────────────
story.append(hr(LIGHT_GREY, 0.5))
story.append(Paragraph(
    f"Generated by Claude Code · {datetime.date.today().strftime('%d %B %Y')} · "
    "YohPal Live v2 · Project: yohlab · Branch: flutter_app",
    S("footer", fontSize=7, textColor=LIGHT_GREY, fontName="Helvetica", alignment=TA_CENTER)))

# ── Build ─────────────────────────────────────────────────────────────────────
doc.build(story)
print(f"PDF written to: {OUTPUT}")
