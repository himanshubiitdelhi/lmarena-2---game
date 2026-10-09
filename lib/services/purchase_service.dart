import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../config/game_config.dart';
import 'telemetry_service.dart';

class VerifiedPurchase {
  const VerifiedPurchase({
    required this.productId,
    required this.token,
    required this.grantId,
    required this.isNewGrant,
    required this.coins,
    required this.gems,
    required this.removeAds,
    required this.starterBundle,
  });

  final String productId;
  final String token;
  final String grantId;
  final bool isNewGrant;
  final int coins;
  final int gems;
  final bool removeAds;
  final bool starterBundle;
}

/// Store client is deliberately fail-closed: real purchases are delivered only
/// after the configured HTTPS verifier confirms the Play purchase token.
class PurchaseService {
  PurchaseService({
    required AnalyticsService analytics,
    required Future<void> Function(VerifiedPurchase purchase) onVerified,
    required void Function(String message) onMessage,
    required void Function() onChanged,
  }) : _analytics = analytics,
       _onVerified = onVerified,
       _onMessage = onMessage,
       _onChanged = onChanged;

  final AnalyticsService _analytics;
  final Future<void> Function(VerifiedPurchase purchase) _onVerified;
  final void Function(String message) _onMessage;
  final void Function() _onChanged;
  final InAppPurchase _store = InAppPurchase.instance;
  final http.Client _http = http.Client();
  final Map<String, ProductDetails> _products = <String, ProductDetails>{};
  final Set<String> _processingTokens = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Future<void> _purchaseQueue = Future<void>.value();
  bool _available = false;
  bool _disposed = false;
  bool _busy = false;
  String? _queryError;

  static const Set<String> productIds = <String>{
    GameConfig.productRemoveAds,
    GameConfig.productGems,
    GameConfig.productStarterBundle,
  };
  static const Set<String> _consumableIds = <String>{GameConfig.productGems};

  bool get available => _available;
  bool get busy => _busy;
  bool get verificationConfigured => GameConfig.purchaseVerificationEndpoint.isNotEmpty;
  String? get queryError => _queryError;
  List<ProductDetails> get products => _products.values.toList(growable: false);
  ProductDetails? product(String id) => _products[id];

  Future<void> initialize() async {
    if (_disposed) return;
    // Listen before querying so pending/restored transactions from the previous
    // process are not missed during startup.
    _purchaseSubscription = _store.purchaseStream.listen(
      _enqueuePurchases,
      onError: (Object error) {
        _onMessage('The Play Store is taking a break. You can keep playing offline.');
      },
    );
    try {
      _available = await _store.isAvailable();
      if (_available) {
        final ProductDetailsResponse response = await _store.queryProductDetails(productIds);
        _products
          ..clear()
          ..addEntries(response.productDetails.map((ProductDetails item) => MapEntry(item.id, item)));
        _queryError = response.error?.message;
      }
    } catch (_) {
      _available = false;
      _queryError = 'Store unavailable';
    }
    _onChanged();
  }

  Future<bool> buy(String productId) async {
    if (!_available || _busy) {
      _onMessage('Purchases are unavailable right now. Your game is saved offline.');
      return false;
    }
    if (!verificationConfigured) {
      _onMessage('Purchases are disabled until secure Play purchase verification is configured.');
      return false;
    }
    final ProductDetails? productDetails = _products[productId];
    if (productDetails == null) {
      _onMessage('This item is not available in the Play Store yet.');
      return false;
    }
    _busy = true;
    _onChanged();
    try {
      final PurchaseParam parameter = PurchaseParam(productDetails: productDetails);
      final bool started = _consumableIds.contains(productId)
          ? await _store.buyConsumable(purchaseParam: parameter, autoConsume: false)
          : await _store.buyNonConsumable(purchaseParam: parameter);
      if (!started) {
        _busy = false;
        _onChanged();
      }
      return started;
    } catch (_) {
      _onMessage('The purchase could not be started. No charge was made by this game.');
      _busy = false;
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) {
      _onMessage('The Play Store is unavailable. Try restoring when you are online.');
      return;
    }
    if (!verificationConfigured) {
      _onMessage('Secure purchase verification is not configured yet.');
      return;
    }
    try {
      await _store.restorePurchases();
      _onMessage('Checking purchases with Google Play…');
    } catch (_) {
      _onMessage('Could not restore purchases right now. Please try again later.');
    }
  }

  void _enqueuePurchases(List<PurchaseDetails> purchases) {
    final List<PurchaseDetails> batch = List<PurchaseDetails>.unmodifiable(purchases);
    _purchaseQueue = _purchaseQueue
        .then<void>((_) => _handlePurchases(batch))
        .catchError((Object _) {
          _processingTokens.clear();
          _busy = false;
          _onChanged();
          _onMessage('Purchase status could not be synchronized. Reopen the shop to retry.');
        });
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      if (_disposed) return;
      if (purchase.status == PurchaseStatus.pending) {
        _busy = true;
        _onMessage('Google Play is processing your purchase…');
        continue;
      }
      if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
        _busy = false;
        if (purchase.status == PurchaseStatus.error) {
          _onMessage('The purchase did not complete. You were not charged by this game.');
        }
        if (purchase.pendingCompletePurchase) {
          await _completePurchase(purchase);
        }
        _onChanged();
        continue;
      }
      if (purchase.status != PurchaseStatus.purchased && purchase.status != PurchaseStatus.restored) {
        continue;
      }
      _busy = true;
      final String token = purchase.verificationData.serverVerificationData;
      if (token.isEmpty || !verificationConfigured) {
        _busy = false;
        _onChanged();
        _onMessage('Purchase received, but secure verification is not configured. Keep the app installed and contact support.');
        continue;
      }
      if (!_processingTokens.add(token)) continue;
      final VerifiedPurchase? verified = await _verifyWithServer(purchase, token);
      if (verified == null) {
        _processingTokens.remove(token);
        _busy = false;
        _onChanged();
        _onMessage('Purchase verification needs a connection. Your item will appear after verification succeeds.');
        continue;
      }
      try {
        await _onVerified(verified);
        // On Google Play a consumable is consumed only after the server verifies
        // the token and the local grant has been durably saved. Consumption is
        // also the acknowledgement for a consumable purchase.
        if (Platform.isAndroid && _consumableIds.contains(purchase.productID)) {
          final InAppPurchaseAndroidPlatformAddition android =
              _store.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
          await android.consumePurchase(purchase);
        } else if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
        await _analytics.log('purchase', <String, Object>{
          'product_id': purchase.productID,
          'status': purchase.status.name,
        });
        _onMessage('Purchase verified. Thanks for supporting Orbit Hop!');
      } catch (_) {
        // Keep the token retryable if local save/acknowledgement failed.
        _processingTokens.remove(token);
        _onMessage('Purchase verified but still syncing. Please reopen the shop shortly.');
      } finally {
        _processingTokens.remove(token);
        _busy = false;
        _onChanged();
      }
    }
  }

  Future<VerifiedPurchase?> _verifyWithServer(PurchaseDetails purchase, String token) async {
    final Uri? endpoint = Uri.tryParse(GameConfig.purchaseVerificationEndpoint);
    if (endpoint == null || !endpoint.hasScheme || endpoint.scheme != 'https') return null;
    try {
      final http.Response response = await _http
          .post(
            endpoint,
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(<String, Object>{
              'packageName': GameConfig.packageName,
              'productId': purchase.productID,
              'purchaseToken': token,
              'purchaseId': purchase.purchaseID ?? '',
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final Object? body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['verified'] != true) return null;
      final String grantId = body['grantId'] is String ? body['grantId'] as String : '';
      if (grantId.isEmpty) return null;
      return VerifiedPurchase(
        productId: purchase.productID,
        token: token,
        grantId: grantId,
        isNewGrant: body['newGrant'] == true,
        coins: _boundedInt(body['coins']),
        gems: _boundedInt(body['gems']),
        removeAds: body['removeAds'] == true,
        starterBundle: body['starterBundle'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  int _boundedInt(Object? value) {
    if (value is! num) return 0;
    return value.toInt().clamp(0, 10000000).toInt();
  }

  Future<void> _completePurchase(PurchaseDetails purchase) async {
    try {
      await _store.completePurchase(purchase);
    } catch (_) {
      // Canceled/error transactions are retried by Play if completion fails.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _purchaseSubscription?.cancel();
    _http.close();
  }
}
