enum FloatingActionType {
  like,
  follow,
  gift,
  chat,
  askAi,
  applyJob,
  acceptHustleTask,
  openMarketProduct,
  pay,
  openWallet,
  openYcios,
}

class FloatingAction {
  final FloatingActionType type;
  final String label;
  final String deepLink;
  final Map<String, dynamic> metadata;
  const FloatingAction({
    required this.type,
    required this.label,
    required this.deepLink,
    this.metadata = const {},
  });
}
