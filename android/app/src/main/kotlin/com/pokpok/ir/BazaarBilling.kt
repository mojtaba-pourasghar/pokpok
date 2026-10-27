package com.pokpok.ir

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import ir.cafebazaar.poolakey.Connection
import ir.cafebazaar.poolakey.ConnectionState
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.config.PaymentConfiguration
import ir.cafebazaar.poolakey.config.SecurityCheck
import ir.cafebazaar.poolakey.request.PurchaseRequest

/**
 * پرداخت درون‌برنامه‌ای کافه‌بازار با کتابخانه‌ی Poolakey، بی‌واسطه‌ی افزونه‌ی flutter_poolakey
 * (که هنوز jcenter() دارد و با Gradle 9 ساخته نمی‌شود).
 *
 * کلید RSA از meta-data «com.pokpok.ir.BAZAAR_RSA» خوانده می‌شود که Gradle از
 * android/services.properties در Manifest می‌گذارد؛ در گیت نیست.
 *
 * متدها: connect، purchase(productId)، purchased() ← فهرست productIdهای خریده‌شده، price(productId).
 */
class BazaarBilling(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var payment: Payment? = null
    private var connection: Connection? = null

    private fun rsaKey(): String? {
        val info = activity.packageManager.getApplicationInfo(
            activity.packageName, android.content.pm.PackageManager.GET_META_DATA)
        return info.metaData?.getString("com.pokpok.ir.BAZAAR_RSA")?.takeIf { it.isNotBlank() }
    }

    private val connected get() = connection?.getState() == ConnectionState.Connected

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(result)
            "purchase" -> purchase(call.argument<String>("productId")!!, result)
            "purchased" -> purchased(result)
            "price" -> price(call.argument<String>("productId")!!, result)
            else -> result.notImplemented()
        }
    }

    private fun connect(result: MethodChannel.Result) {
        if (connected) return result.success(true)
        val key = rsaKey() ?: return result.error("NO_KEY", "bazaar.rsa در services.properties خالی است", null)
        val p = Payment(context = activity, config = PaymentConfiguration(localSecurityCheck = SecurityCheck.Enable(rsaPublicKey = key)))
        payment = p
        var answered = false
        connection = p.connect {
            connectionSucceed { if (!answered) { answered = true; result.success(true) } }
            connectionFailed { if (!answered) { answered = true; result.error("CONNECT_FAILED", it.toString(), null) } }
            disconnected { if (!answered) { answered = true; result.success(false) } }
        }
    }

    private fun purchase(productId: String, result: MethodChannel.Result) {
        val p = payment
        if (p == null || !connected) return result.error("NOT_CONNECTED", "اول connect", null)
        PurchaseActivity.start(activity, p, productId, result)
    }

    private fun purchased(result: MethodChannel.Result) {
        val p = payment
        if (p == null || !connected) return result.error("NOT_CONNECTED", "اول connect", null)
        p.getPurchasedProducts {
            querySucceed { items -> result.success(items.map { it.productId }) }
            queryFailed { result.error("QUERY_FAILED", it.toString(), null) }
        }
    }

    private fun price(productId: String, result: MethodChannel.Result) {
        val p = payment
        if (p == null || !connected) return result.error("NOT_CONNECTED", "اول connect", null)
        p.getInAppSkuDetails(skuIds = listOf(productId)) {
            getSkuDetailsSucceed { list -> result.success(list.firstOrNull()?.price) }
            getSkuDetailsFailed { result.error("SKU_FAILED", it.toString(), null) }
        }
    }

    fun disconnect() {
        connection?.disconnect()
        connection = null
    }
}

/** صفحه‌ی شفافی که جریان خرید بازار را باز می‌کند؛ Poolakey به ActivityResultRegistry نیاز دارد. */
class PurchaseActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val p = pendingPayment
        val id = pendingProduct
        val r = pendingResult
        if (p == null || id == null || r == null) return finish()
        clear()
        p.purchaseProduct(activityResultRegistry, PurchaseRequest(id, null, null)) {
            purchaseSucceed { r.success("ok"); finish() }
            purchaseCanceled { r.success("cancelled"); finish() }
            purchaseFailed { r.error("PURCHASE_FAILED", it.toString(), null); finish() }
            purchaseFlowBegan { }
            failedToBeginFlow { r.error("FAILED_TO_BEGIN", it.toString(), null); finish() }
        }
    }

    companion object {
        private var pendingPayment: Payment? = null
        private var pendingProduct: String? = null
        private var pendingResult: MethodChannel.Result? = null

        private fun clear() {
            pendingPayment = null; pendingProduct = null; pendingResult = null
        }

        fun start(activity: Activity, payment: Payment, productId: String, result: MethodChannel.Result) {
            pendingPayment = payment
            pendingProduct = productId
            pendingResult = result
            activity.startActivity(Intent(activity, PurchaseActivity::class.java))
        }
    }
}
