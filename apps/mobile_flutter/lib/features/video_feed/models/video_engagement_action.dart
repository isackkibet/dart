import 'package:flutter/material.dart';

enum VideoEngagementAction {
  // ── Always-visible tier (default rail, positions 0-7) ──────────────────────
  follow,
  like,
  comment,
  share,
  favourite,
  chat,
  askAI,
  more,

  // ── Extended rail (visible after More / scroll) ────────────────────────────
  views,
  report,
  notInterested,
  blockCreator,
  download,
  likePrivately,
  commentPrivately,

  // ── Disruptive YohPal actions ──────────────────────────────────────────────
  shop,
  claimCoupon,
  tipCreator,
  joinCreatorLive,
  duetReact,
  translate,
  summarise,
  saveToCollection,
  watchLater,
  applyBookRegister,
  createRemix,
  sponsorCreator,
  inviteFriend,
  addToMission,
  earnFromAd,
  followTopic,
  creatorMarketplace,
}

class VideoEngagementActionMeta {
  final VideoEngagementAction action;
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Color activeColor;
  final bool requiresAuth;

  const VideoEngagementActionMeta({
    required this.action,
    required this.icon,
    this.activeIcon,
    required this.label,
    this.activeColor = Colors.white,
    this.requiresAuth = true,
  });
}

const List<VideoEngagementActionMeta> kEngagementActionMeta = [
  // default visible
  VideoEngagementActionMeta(
    action: VideoEngagementAction.follow,
    icon: Icons.person_add_outlined,
    activeIcon: Icons.person_remove_outlined,
    label: 'Follow',
    activeColor: Colors.cyanAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.like,
    icon: Icons.favorite_border,
    activeIcon: Icons.favorite,
    label: 'Like',
    activeColor: Colors.redAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.comment,
    icon: Icons.chat_bubble_outline,
    label: 'Comment',
    activeColor: Colors.white,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.share,
    icon: Icons.share_outlined,
    label: 'Share',
    activeColor: Colors.white,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.favourite,
    icon: Icons.bookmark_border,
    activeIcon: Icons.bookmark,
    label: 'Save',
    activeColor: Colors.cyanAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.chat,
    icon: Icons.send_outlined,
    label: 'Chat',
    activeColor: Colors.white,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.askAI,
    icon: Icons.auto_awesome_outlined,
    label: 'Ask AI',
    activeColor: Colors.purpleAccent,
    requiresAuth: false,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.more,
    icon: Icons.expand_more,
    activeIcon: Icons.expand_less,
    label: 'More',
    activeColor: Colors.white,
    requiresAuth: false,
  ),
  // extended
  VideoEngagementActionMeta(
    action: VideoEngagementAction.views,
    icon: Icons.visibility_outlined,
    label: 'Views',
    activeColor: Colors.white,
    requiresAuth: false,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.report,
    icon: Icons.flag_outlined,
    label: 'Report',
    activeColor: Colors.orangeAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.notInterested,
    icon: Icons.do_not_disturb_on_outlined,
    label: 'Not Interested',
    activeColor: Colors.grey,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.blockCreator,
    icon: Icons.block_outlined,
    label: 'Block',
    activeColor: Colors.grey,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.download,
    icon: Icons.download_outlined,
    label: 'Download',
    activeColor: Colors.white,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.likePrivately,
    icon: Icons.favorite_outline,
    activeIcon: Icons.favorite,
    label: 'Like Privately',
    activeColor: Colors.pink,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.commentPrivately,
    icon: Icons.lock_outlined,
    label: 'Private Comment',
    activeColor: Colors.pink,
  ),
  // disruptive
  VideoEngagementActionMeta(
    action: VideoEngagementAction.shop,
    icon: Icons.shopping_bag_outlined,
    label: 'Shop',
    activeColor: Colors.greenAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.claimCoupon,
    icon: Icons.local_offer_outlined,
    label: 'Coupon',
    activeColor: Colors.orangeAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.tipCreator,
    icon: Icons.card_giftcard_outlined,
    label: 'Tip / Gift',
    activeColor: Colors.amberAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.joinCreatorLive,
    icon: Icons.live_tv_outlined,
    label: 'Join Live',
    activeColor: Colors.redAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.duetReact,
    icon: Icons.people_outline,
    label: 'Duet / React',
    activeColor: Colors.tealAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.translate,
    icon: Icons.translate_outlined,
    label: 'Translate',
    activeColor: Colors.blueAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.summarise,
    icon: Icons.summarize_outlined,
    label: 'Summarise',
    activeColor: Colors.purpleAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.saveToCollection,
    icon: Icons.folder_outlined,
    label: 'Collection',
    activeColor: Colors.cyanAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.watchLater,
    icon: Icons.watch_later_outlined,
    activeIcon: Icons.watch_later,
    label: 'Watch Later',
    activeColor: Colors.tealAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.applyBookRegister,
    icon: Icons.how_to_reg_outlined,
    label: 'Apply / Book',
    activeColor: Colors.greenAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.createRemix,
    icon: Icons.loop_outlined,
    label: 'Remix',
    activeColor: Colors.tealAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.sponsorCreator,
    icon: Icons.workspace_premium_outlined,
    label: 'Sponsor',
    activeColor: Colors.amberAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.inviteFriend,
    icon: Icons.group_add_outlined,
    label: 'Invite',
    activeColor: Colors.cyanAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.addToMission,
    icon: Icons.emoji_events_outlined,
    label: 'Mission',
    activeColor: Colors.orangeAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.earnFromAd,
    icon: Icons.monetization_on_outlined,
    label: 'Earn',
    activeColor: Colors.amberAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.followTopic,
    icon: Icons.tag_outlined,
    label: 'Topic',
    activeColor: Colors.blueAccent,
  ),
  VideoEngagementActionMeta(
    action: VideoEngagementAction.creatorMarketplace,
    icon: Icons.storefront_outlined,
    label: 'Marketplace',
    activeColor: Colors.greenAccent,
  ),
];

VideoEngagementActionMeta metaFor(VideoEngagementAction action) =>
    kEngagementActionMeta.firstWhere((m) => m.action == action);

// First 8 are always visible; tap More to reveal the rest
const List<VideoEngagementAction> kDefaultVisibleActions = [
  VideoEngagementAction.follow,
  VideoEngagementAction.like,
  VideoEngagementAction.comment,
  VideoEngagementAction.share,
  VideoEngagementAction.favourite,
  VideoEngagementAction.chat,
  VideoEngagementAction.askAI,
  VideoEngagementAction.more,
];
