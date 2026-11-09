package com.pokpok.ir

import android.app.Activity
import android.content.pm.PackageManager
import com.adivery.sdk.Adivery
import com.adivery.sdk.AdiveryListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * تبلیغ تمام‌صفحه‌ی ادیوری بعد از هر بخش، فقط در نسخه‌ی رایگان (تصمیمش با Dart است: AccessStore.showsAds).
 *
 * شناسه‌ی برنامه و شناسه‌ی جایگاه (placement) از meta-dataهای «com.pokpok.ir.ADIVERY_APP_ID» و
 * «com.pokpok.ir.ADIVERY_INTERSTITIAL» خوانده می‌شوند که Gradle از android/services.properties در Manifest
 * می‌گذارد؛ خالی بودنشان یعنی بی‌تبلیغ (نه خطا).
 *
 * متدها:
 * - prepare: ادیوری را (یک بار) راه می‌اندازد و تبلیغ را بارگیری می‌کند.
 * - show: اگر آماده است نشان می‌دهد و بعد از بسته شدن true برمی‌گرداند؛ وگرنه فوراً false و بارگیری دوباره.
 *
 * ادیوری بعد از هر نمایش خودش تبلیغ بعدی را بارگیری می‌کند.
 */
class AdiveryAds(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var placement: String? = null
    private var pending: MethodChannel.Result? = null
    private var opened = false
    private val main = android.os.Handler(android.os.Looper.getMainLooper())

    /** اگر تبلیغ چند ثانیه بعد از showAd باز نشد (خطای نمایش)، بازی بی‌معطلی ادامه می‌دهد. */
    private val notOpened = Runnable { if (!opened) answer(false) }

    private val listener = object : AdiveryListener() {
        override fun onInterstitialAdShown(placementId: String) {
            opened = true
        }

        override fun onInterstitialAdClosed(placementId: String) = answer(true)

        /** خطاهای بارگیری و نمایش از همین‌جا گزارش می‌شوند. */
        override fun log(placementId: String, message: String) {
            android.util.Log.d("PopoAds", "[$placementId] $message")
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> result.success(setup())
            "show" -> show(result)
            else -> result.notImplemented()
        }
    }

    private fun meta(name: String): String? {
        val info = activity.packageManager.getApplicationInfo(activity.packageName, PackageManager.GET_META_DATA)
        return info.metaData?.getString(name)?.trim()?.takeIf { it.isNotEmpty() }
    }

    /** true اگر شناسه‌ها هست و ادیوری آماده‌ی بارگیری است. */
    private fun setup(): Boolean {
        placement?.let {
            if (!Adivery.isLoaded(it)) Adivery.prepareInterstitialAd(activity, it)
            return true
        }
        val appId = meta("com.pokpok.ir.ADIVERY_APP_ID") ?: return false
        val id = meta("com.pokpok.ir.ADIVERY_INTERSTITIAL") ?: return false
        Adivery.setLoggingEnabled(BuildConfigFlags.debuggable(activity))
        Adivery.configure(activity.application, appId)
        Adivery.addPlacementListener(id, listener)
        Adivery.prepareInterstitialAd(activity, id)
        placement = id
        return true
    }

    private fun show(result: MethodChannel.Result) {
        if (pending != null) return result.success(false)
        if (!setup()) return result.success(false)
        val id = placement!!
        if (!Adivery.isLoaded(id)) {
            Adivery.prepareInterstitialAd(activity, id)
            return result.success(false)
        }
        pending = result
        opened = false
        Adivery.showAd(id)
        main.postDelayed(notOpened, 6000)
    }

    private fun answer(shown: Boolean) {
        main.removeCallbacks(notOpened)
        val r = pending ?: return
        pending = null
        r.success(shown)
    }

    fun dispose() {
        placement?.let { Adivery.removePlacementListener(it) }
        answer(false)
    }
}

/** BuildConfig در AGP 8 پیش‌فرض خاموش است؛ debuggable از خود برنامه خوانده می‌شود. */
private object BuildConfigFlags {
    fun debuggable(activity: Activity): Boolean =
        (activity.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
}
