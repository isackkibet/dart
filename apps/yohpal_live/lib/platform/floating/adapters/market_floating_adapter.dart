import 'floating_module_adapter.dart';
import '../context/floating_context.dart';
import '../actions/floating_action.dart';

class MarketFloatingAdapter implements FloatingModuleAdapter {
  @override
  String get moduleName => 'market';
  @override
  bool get supportsFloating => true;
  @override
  Future<List<FloatingAction>> resolveActions(FloatingContext context) async {
    return [
      FloatingAction(
        type: FloatingActionType.openMarketProduct,
        label: 'Open Product',
        deepLink: 'yohpal://market/product/${context.entityId}',
      ),
      FloatingAction(
        type: FloatingActionType.openWallet,
        label: 'Pay',
        deepLink: 'yohpal://wallet/pay?productId=${context.entityId}',
      ),
    ];
  }
  @override
  Future<void> onFloatingStarted(FloatingContext context) async {}
  @override
  Future<void> onFloatingStopped(FloatingContext context) async {}
}
