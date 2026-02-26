import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/constants/pricing_constants.dart';
import '../../core/constants/app_constants.dart';

final subscriptionControllerProvider = StateNotifierProvider<SubscriptionController, AsyncValue<List<ProductDetails>>>((ref) {
  return SubscriptionController();
});

class SubscriptionController extends StateNotifier<AsyncValue<List<ProductDetails>>> {
  SubscriptionController() : super(const AsyncValue.loading()) {
    _init();
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  Future<void> _init() async {
    final available = await _iap.isAvailable();
    if (!available) {
      state = AsyncValue.error("Store not available", StackTrace.current);
      return;
    }

    // Listen to purchase updates (Success, Pending, Error)
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => state = AsyncValue.error(error, StackTrace.current),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(PricingConstants.productIds);
    if (response.error != null) {
      state = AsyncValue.error(response.error!, StackTrace.current);
    } else {
      state = AsyncValue.data(response.productDetails);
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased || 
          purchase.status == PurchaseStatus.restored) {
        await _grantPremiumStatus();
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        // Handle error silently or log it
      }
    }
  }

  // Grant Premium in Firestore
  Future<void> _grantPremiumStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'isPremium': true});
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}