package com.pokpok.ir

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * کد بومی برنامه (همان طرح گوش‌یار)، سه کانال:
 * - com.pokpok.ir/billing: پرداخت کافه‌بازار (BazaarBilling.kt)
 * - com.pokpok.ir/native: صفحه‌ی برنامه در بازار، پیوند، و خبرها و اعلان‌ها (NoticeCenter.kt):
 *   اجازه‌ی اعلان، روشن/خاموش کار پس‌زمینه، فرستادن خبر به نوار، صرفه‌جویی باتری، و لمس اعلان.
 * - com.pokpok.ir/storage: فضای آزاد حافظه برای صفحه‌ی دانلودها
 *
 * هیچ سرویس پوشی در کار نیست: خبر روی سرور است و برنامه خودش آن را می‌خواند.
 */
class MainActivity : FlutterActivity() {
    private var billing: BazaarBilling? = null
    private var native: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // فضای آزاد حافظه‌ی برنامه برای صفحه‌ی دانلودها (lib/core/assets/storage_info.dart).
        MethodChannel(messenger, "com.pokpok.ir/storage").setMethodCallHandler { call, result ->
            when (call.method) {
                "freeBytes" -> result.success(StatFs(filesDir.path).availableBytes)
                else -> result.notImplemented()
            }
        }
        billing = BazaarBilling(this).also { MethodChannel(messenger, "com.pokpok.ir/billing").setMethodCallHandler(it) }
        native = MethodChannel(messenger, "com.pokpok.ir/native").also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "openStorePage" -> result.success(openStorePage(call.argument<String>("packageName")!!))
                    "openUrl" -> result.success(openUrl(call.argument<String>("url") ?: ""))
                    "appVersion" -> result.success(appVersion())
                    "notificationsAllowed" -> result.success(NoticeCenter.permitted(this))
                    "requestNotifications" -> {
                        requestNotifications(call.argument<Boolean>("settings") != false)
                        result.success(null)
                    }
                    "scheduleNotices" -> { NoticeCenter.configure(this, call.argument<String>("url")); result.success(null) }
                    // خبر بعدی به نوار اعلان، روی رشته‌ی جدا (تصویر شاید دانلود شود).
                    "postNotices" -> {
                        val app = applicationContext
                        Thread({ runCatching { NoticeCenter.post(app) } }, "popo-notice-post").start()
                        result.success(null)
                    }
                    "runsInBackground" -> result.success(NoticeCenter.runsInBackground(this))
                    "askBackground" -> { NoticeCenter.askBackground(this); result.success(null) }
                    "askBackgroundOnce" -> { NoticeCenter.askBackgroundOnce(this); result.success(null) }
                    "hasAutostart" -> result.success(NoticeCenter.hasAutostart())
                    "openAutostart" -> { NoticeCenter.openAutostart(this); result.success(null) }
                    "takeLaunchNotice" -> result.success(takeNotice(intent))
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        billing?.disconnect()
        super.onDestroy()
    }

    /** اعلانی در نوار لمس شد وقتی برنامه از قبل باز بود. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        takeNotice(intent)?.let { native?.invokeMethod("noticeTapped", it) }
    }

    /**
     * یک نگاه آخر هنگام بسته شدن: کودکی که همین الان گوشی را گذاشته به احتمال زیاد هنوز نزدیک آن است،
     * و این یک انتظار پانزده‌دقیقه‌ای را به هیچ می‌رساند.
     */
    override fun onPause() {
        NoticeWork.once(applicationContext)
        super.onPause()
    }

    /** «بله» به اجازه‌ی اعلان: خبرهایی که منتظر همین پاسخ بودند همین حالا به نوار می‌روند. */
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NoticeCenter.PERMISSION_REQUEST) return
        val app = applicationContext
        Thread({ runCatching { NoticeCenter.post(app) } }, "popo-notice-post").start()
        // اعلان حالا روشن است؛ چیز بعدی میان خبر و برنامه‌ی بسته، صرفه‌جویی باتری است.
        NoticeCenter.askBackgroundOnce(this)
        native?.invokeMethod("permissionAnswered", NoticeCenter.permitted(this))
    }

    /**
     * خبری که از نوار اعلان لمس شده: {id, screen, show}. فقط یک بار — چرخش صفحه یا برگشتن از جای دیگر
     * نباید دوباره انجامش دهد.
     */
    private fun takeNotice(intent: Intent?): Map<String, Any>? {
        val id = intent?.getStringExtra(NoticeCenter.EXTRA_ID) ?: return null
        val out = mapOf<String, Any>(
            "id" to id,
            "screen" to (intent.getStringExtra(NoticeCenter.EXTRA_SCREEN) ?: ""),
            "show" to intent.getBooleanExtra(NoticeCenter.EXTRA_SHOW, false),
        )
        intent.removeExtra(NoticeCenter.EXTRA_ID)
        intent.removeExtra(NoticeCenter.EXTRA_SCREEN)
        intent.removeExtra(NoticeCenter.EXTRA_SHOW)
        return out
    }

    /** نسخه‌ی همین برنامه، برای «نسخه‌ی تازه آمده» (BuildConfig در AGP 8 پیش‌فرض خاموش است). */
    private fun appVersion(): String = try {
        packageManager.getPackageInfo(packageName, 0).versionName ?: ""
    } catch (_: Exception) {
        ""
    }

    /** صفحه‌ی برنامه در کافه‌بازار؛ اگر بازار نصب نبود، همان صفحه در مرورگر. */
    private fun openStorePage(packageName: String): Boolean {
        val bazaar = Intent(Intent.ACTION_VIEW, Uri.parse("bazaar://details?id=$packageName"))
            .setPackage("com.farsitel.bazaar")
        val web = Intent(Intent.ACTION_VIEW, Uri.parse("https://cafebazaar.ir/app/$packageName"))
        for (intent in listOf(bazaar, web)) {
            try {
                startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (_: ActivityNotFoundException) {
            }
        }
        return false
    }

    /** پیوند یک خبر؛ فقط https. */
    private fun openUrl(url: String): Boolean {
        if (!url.startsWith("https://")) return false
        return try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    /**
     * اندروید ۱۳ به بعد برای نمایش اعلان اجازه می‌خواهد. اگر قبلاً «نه» گفته شده و سیستم دیگر پنجره
     * نشان نمی‌دهد، صفحه‌ی اعلان‌های برنامه در تنظیمات باز می‌شود — فقط اگر [settings] (بخش والدین)؛
     * پرسیدن خودکار هنگام رسیدن خبر فقط پنجره‌ی خود سیستم را نشان می‌دهد.
     */
    private fun requestNotifications(settings: Boolean = true) {
        if (NoticeCenter.permitted(this)) return
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NoticeCenter.PERMISSION_REQUEST)
            return
        }
        if (!settings || Build.VERSION.SDK_INT < 26) return
        try {
            startActivity(
                Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName),
            )
        } catch (_: Exception) {
            // روی این گوشی صفحه‌ای برای باز کردن نیست.
        }
    }
}
