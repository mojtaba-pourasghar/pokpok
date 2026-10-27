import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/billing/billing.dart';
import 'package:popo/core/billing/access_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBilling implements Billing {
  FakeBilling({this.connects = true, this.owned = const [], this.result = PurchaseResult.purchased});

  bool connects;
  List<String>? owned;
  PurchaseResult result;
  int purchases = 0;

  @override
  Future<bool> connect() async => connects;

  @override
  Future<List<String>?> purchased() async => owned;

  @override
  Future<String?> price(String productId) async => '۱۸۰٬۰۰۰ تومان';

  @override
  Future<PurchaseResult> purchase(String productId) async {
    purchases++;
    return result;
  }
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('debug: هیچ مرحله‌ای پشت خرید نیست', () {
    final a = AccessStore(prefs, FakeBilling(), paywall: false);
    expect(a.everythingOpen, isTrue);
    expect(a.needsPurchase(5), isFalse);
  });

  test('release بدون خرید: فقط مرحله‌ی ۱ رایگان', () {
    final a = AccessStore(prefs, FakeBilling(), paywall: true);
    expect(a.needsPurchase(0), isFalse);
    expect(a.needsPurchase(1), isTrue);
    expect(a.price, AccessStore.fallbackPrice);
  });

  test('خرید موفق همه را باز می‌کند و ذخیره می‌شود', () async {
    final billing = FakeBilling();
    final a = AccessStore(prefs, billing, paywall: true);
    expect(await a.buy(), PurchaseResult.purchased);
    expect(a.owned, isTrue);
    expect(a.needsPurchase(7), isFalse);
    expect(AccessStore(prefs, const NoBilling(), paywall: true).owned, isTrue, reason: 'بعد از بستن برنامه هم می‌ماند');
  });

  test('لغو خرید یا نبود بازار چیزی را باز نمی‌کند', () async {
    final a = AccessStore(prefs, FakeBilling(result: PurchaseResult.cancelled), paywall: true);
    expect(await a.buy(), PurchaseResult.cancelled);
    expect(a.owned, isFalse);
    final b = AccessStore(prefs, FakeBilling(connects: false), paywall: true);
    expect(await b.buy(), PurchaseResult.unavailable);
    expect(b.owned, isFalse);
  });

  test('همگام‌سازی: خرید قبلی از بازار پیدا می‌شود؛ بی‌اینترنت وضعیت ذخیره‌شده می‌ماند', () async {
    final a = AccessStore(prefs, FakeBilling(owned: [AccessStore.productId]), paywall: true);
    await a.sync();
    expect(a.owned, isTrue);
    final offline = AccessStore(prefs, FakeBilling(owned: null), paywall: true);
    await offline.sync();
    expect(offline.owned, isTrue);
    expect(await AccessStore(prefs, FakeBilling(connects: false), paywall: true).restore(), isNull);
  });
}
