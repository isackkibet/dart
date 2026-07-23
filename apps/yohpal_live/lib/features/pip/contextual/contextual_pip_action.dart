enum ContextualPipActionType {
  like,
  follow,
  gift,
  chat,
  askAi,
  continueInJobs,
  continueInHustle,
  openMarketProduct,
}

class ContextualPipAction {
  final ContextualPipActionType type;
  final String label;
  final String deepLink;
  final Map<String, dynamic> metadata;
  const ContextualPipAction({
    required this.type,
    required this.label,
    required this.deepLink,
    this.metadata = const {},
  });
}
