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

  test('رایگان: تبلیغ نشان داده می‌شود، با قیمت پیش‌فرض', () {
    final a = AccessStore(prefs, FakeBilling());
    expect(a.owned, isFalse);
    expect(a.showsAds, isTrue);
    expect(a.price, AccessStore.fallbackPrice);
  });

  test('خرید موفق تبلیغ را خاموش می‌کند و ذخیره می‌شود', () async {
    final billing = FakeBilling();
    final a = AccessStore(prefs, billing);
    expect(await a.buy(), PurchaseResult.purchased);
    expect(a.owned, isTrue);
    expect(a.showsAds, isFalse);
    expect(AccessStore(prefs, const NoBilling()).showsAds, isFalse, reason: 'بعد از بستن برنامه هم می‌ماند');
  });

  test('لغو خرید یا نبود بازار تبلیغ را خاموش نمی‌کند', () async {
    final a = AccessStore(prefs, FakeBilling(result: PurchaseResult.cancelled));
    expect(await a.buy(), PurchaseResult.cancelled);
    expect(a.showsAds, isTrue);
    final b = AccessStore(prefs, FakeBilling(connects: false));
    expect(await b.buy(), PurchaseResult.unavailable);
    expect(b.showsAds, isTrue);
  });

  test('همگام‌سازی: خرید قبلی از بازار پیدا می‌شود؛ بی‌اینترنت وضعیت ذخیره‌شده می‌ماند', () async {
    final a = AccessStore(prefs, FakeBilling(owned: [AccessStore.productId]));
    await a.sync();
    expect(a.owned, isTrue);
    final offline = AccessStore(prefs, FakeBilling(owned: null));
    await offline.sync();
    expect(offline.owned, isTrue);
    expect(await AccessStore(prefs, FakeBilling(connects: false)).restore(), isNull);
  });
}
