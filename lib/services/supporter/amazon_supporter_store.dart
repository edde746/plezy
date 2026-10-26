import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/// Amazon Fire OS bridge for the lifetime unlock.
///
/// The Android store provider is selected at build time with
/// `openiapStore=amazon`; the same Dart API then talks to Amazon Appstore IAP.
class AmazonSupporterStore {
  AmazonSupporterStore({FlutterInappPurchase? iap}) : _iap = iap ?? FlutterInappPurchase.instance;

  final FlutterInappPurchase _iap;
  Future<bool>? _connection;

  Stream<Purchase> get purchases => _iap.purchaseUpdatedListener;

  Stream<PurchaseError> get purchaseErrors => _iap.purchaseErrorListener;

  Future<bool> initialize() async {
    final connection = _connection ??= _initialize();
    try {
      return await connection;
    } catch (_) {
      if (identical(_connection, connection)) _connection = null;
      rethrow;
    }
  }

  Future<bool> _initialize() async {
    final connected = await _iap.initConnection();
    if (!connected) throw StateError('Amazon Appstore billing is unavailable');
    return true;
  }

  Future<List<Product>> queryProducts(Set<String> productIds) async {
    await initialize();
    return _iap.fetchProducts<Product>(skus: productIds.toList(), type: ProductQueryType.InApp);
  }

  Future<void> purchase(String productId) async {
    await initialize();
    await _iap.requestPurchase(
      RequestPurchaseProps.inApp((apple: null, google: RequestPurchaseAndroidProps(skus: [productId]))),
    );
  }

  Future<void> syncForRestore() async {
    await initialize();
    await _iap.restorePurchases();
  }

  Future<List<Purchase>> queryHistory() async {
    await initialize();
    return _iap.getAvailablePurchases();
  }

  Future<void> finish(Purchase purchase) async {
    await _iap.finishTransaction(purchase: purchase, isConsumable: false);
  }

  Future<void> dispose() async {
    if (_connection == null) return;
    await _iap.endConnection();
  }
}
