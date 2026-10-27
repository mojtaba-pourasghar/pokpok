package com.pokpok.ir

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Base64
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.KeyFactory
import java.security.MessageDigest
import java.security.PublicKey
import java.security.Signature
import java.security.interfaces.RSAPublicKey
import java.security.spec.X509EncodedKeySpec

/**
 * خبرها و اعلان‌ها، سمت اندروید — بدون هیچ سرویس پوشی.
 *
 * خبر روی سرور گذاشته می‌شود (استودیو ← «انتشار» ← popo/notices.json روی R2) و برنامه خودش آن را
 * می‌خواند: هر دقیقه وقتی باز است (lib/features/notices/notice_host.dart) و حدود هر ربع ساعت وقتی بسته است
 * (NoticeWork از راه WorkManager، و NoticeAlarm که از میان Doze هم رد می‌شود). هر چه تازه باشد، یکی
 * یکی به نوار اعلان می‌رود.
 *
 * همان قاعده‌های هوهو ریاضی:
 *  - فقط فایل امضاشده (assets/notices/notice-key.pub)؛ تصویر با sha256 درون متن امضاشده.
 *  - یکی در هر نوبت، فوری‌ترین اول، و بعدی نه زودتر از [GAP_MS].
 *  - خبر دیر، خبر نیست: مهلت گذشته یعنی هرگز نشان داده نمی‌شود.
 *
 * وضعیت مشترک با Dart در FlutterSharedPreferences است (پیشوند «flutter.»): روشن/خاموش و «دیده شد»
 * را Dart می‌نویسد؛ «به نوار رفت» را فقط همین‌جا. چیزی از گوشی فرستاده نمی‌شود.
 */
object NoticeCenter {
    const val CHANNEL = "popo_news"
    const val GAP_MS = 60_000L
    const val PERMISSION_REQUEST = 7301

    const val EXTRA_ID = "popo.notice_id"
    const val EXTRA_SCREEN = "popo.notice_screen"
    const val EXTRA_SHOW = "popo.notice_show"

    private const val ANYWHERE = "ANYWHERE"
    private const val FLUTTER = "FlutterSharedPreferences"
    private const val OWN = "popo_notices"
    private const val K_ON = "flutter.popo.notices.on"
    private const val K_SEEN = "flutter.popo.notices.seen"
    private const val K_TOLD = "flutter.popo.notices.told"
    private const val K_CACHE = "flutter.popo.notices.cache"
    private const val K_CHECK = "flutter.popo.notices.lastCheck"
    private const val K_RESULT = "flutter.popo.notices.lastResult"
    private const val K_TRAY_AT = "flutter.popo.notices.lastTrayAt"
    private const val KEY_ASSET = "flutter_assets/assets/notices/notice-key.pub"
    private const val MAX_BYTES = 256 * 1024
    private const val MAX_IMAGE = 2 * 1024 * 1024
    private const val WIDEST = 1080

    @Volatile private var key: PublicKey? = null

    class Notice(
        val id: String,
        val title: String,
        val body: String,
        val image: String,
        val imageSha256: String,
        val screen: String,
        val from: Long,
        val until: Long,
    ) {
        fun current(now: Long) = (from <= 0 || now >= from) && (until <= 0 || now <= until)
        val destination get() = if (screen == ANYWHERE) "" else screen
        val hasImage get() = image.isNotEmpty() && imageSha256.length == 64
    }

    private fun flutter(c: Context): SharedPreferences = c.getSharedPreferences(FLUTTER, Context.MODE_PRIVATE)
    private fun own(c: Context): SharedPreferences = c.getSharedPreferences(OWN, Context.MODE_PRIVATE)

    // ── روشن، خاموش، اجازه ────────────────────────────────────────────────────

    /** نشانی فایل خبرها را Dart می‌دهد (NoticesStore.schedule)؛ null یعنی «خاموش». */
    fun configure(c: Context, url: String?) {
        val app = c.applicationContext
        if (url.isNullOrBlank() || !url.startsWith("https://")) {
            own(app).edit().remove("url").apply()
            NoticeWork.cancel(app)
            return
        }
        own(app).edit().putString("url", url).apply()
        NoticeWork.schedule(app)
    }

    private fun url(c: Context): String? = own(c).getString("url", null)

    /** نشانی داده شده و والدین خبرها را خاموش نکرده‌اند. */
    fun allowed(c: Context): Boolean = url(c) != null && flutter(c).getBoolean(K_ON, true)

    /** اندروید ۱۳ به بعد تا کسی یک بار «بله» نگوید اعلانی نشان نمی‌دهد. */
    fun permitted(c: Context): Boolean =
        (Build.VERSION.SDK_INT < 33 ||
            c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
            NotificationManagerCompat.from(c).areNotificationsEnabled()

    /** آیا سیستم می‌گذارد بررسی‌ها وقتی گوشی خواب است هم انجام شوند؟ */
    fun runsInBackground(c: Context): Boolean {
        val power = c.getSystemService(PowerManager::class.java)
        return power == null || power.isIgnoringBatteryOptimizations(c.packageName)
    }

    /**
     * یک بار، برای همیشه، می‌پرسد که برنامه از صرفه‌جویی باتری بیرون بماند — بی آن Doze و App Standby
     * بررسی پس‌زمینه را ساعت‌ها عقب می‌اندازند. فقط وقتی اعلان اجازه دارد و خبرها روشن است؛ «نه»
     * محترم است (بخش والدین راه دوباره پرسیدن را دارد).
     */
    fun askBackgroundOnce(activity: Activity) {
        val prefs = own(activity)
        if (prefs.getBoolean("askedBackground", false)) return
        if (!permitted(activity) || !allowed(activity) || runsInBackground(activity)) return
        prefs.edit().putBoolean("askedBackground", true).apply()
        askBackground(activity)
    }

    /** پنجره‌ی خود سیستم؛ اگر سازنده‌ی گوشی پنهانش کرده باشد، فهرست برنامه‌ها. */
    fun askBackground(activity: Activity) {
        try {
            activity.startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:${activity.packageName}")),
            )
        } catch (_: Exception) {
            try {
                activity.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Exception) {
                // روی این گوشی چیزی برای باز کردن نیست؛ بررسی‌ها کندتر، ولی انجام می‌شوند.
            }
        }
    }

    /**
     * صفحه‌های «اجرای خودکار» سازنده‌ها. روی شیائومی، هواوی، آنر، اوپو، ویوو، ریلمی، وان‌پلاس، آسوس و
     * سامسونگ، کشیدن برنامه از فهرست برنامه‌های اخیر آلارم‌ها و کارهای WorkManager را هم می‌کشد، تا
     * وقتی که اجرای خودکار برای برنامه روشن نشده باشد — و صرفه‌جویی باتری اندروید به آن کاری ندارد.
     */
    private val autostartScreens = listOf(
        "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
        "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        "com.huawei.systemmanager" to "com.huawei.systemmanager.optimize.process.ProtectActivity",
        "com.hihonor.systemmanager" to "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
        "com.coloros.safecenter" to "com.coloros.safecenter.startupapp.StartupAppListActivity",
        "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
        "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
        "com.asus.mobilemanager" to "com.asus.mobilemanager.entry.FunctionActivity",
        "com.samsung.android.lool" to "com.samsung.android.sm.ui.battery.BatteryActivity",
    )

    private val autostartMakers = setOf(
        "xiaomi", "redmi", "poco", "huawei", "honor", "oppo", "realme", "oneplus", "vivo", "iqoo", "asus", "samsung",
    )

    /** آیا این گوشی از سازنده‌ای است که برنامه‌ی بسته را بی «اجرای خودکار» نگه نمی‌دارد؟ */
    fun hasAutostart(): Boolean =
        Build.MANUFACTURER.lowercase() in autostartMakers || Build.BRAND.lowercase() in autostartMakers

    /**
     * صفحه‌ی اجرای خودکار سازنده؛ اگر هیچ‌کدام روی این گوشی نبود، صفحه‌ی اطلاعات برنامه در تنظیمات
     * (که «باتری ← بدون محدودیت» از همان‌جاست). بازکردن با نام کامل اکتیویتی به اعلام در queries نیاز
     * ندارد؛ نبودنش فقط ActivityNotFoundException یا SecurityException است.
     */
    fun openAutostart(activity: Activity) {
        for ((pkg, cls) in autostartScreens) {
            try {
                activity.startActivity(Intent().setClassName(pkg, cls).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return
            } catch (_: Exception) {
                // این سازنده نیست یا صفحه جابه‌جا شده؛ بعدی.
            }
        }
        try {
            activity.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}")),
            )
        } catch (_: Exception) {
            // روی این گوشی چیزی برای باز کردن نیست.
        }
    }

    // ── خواندن از سرور ─────────────────────────────────────────────────────────

    /**
     * یک نوبت پس‌زمینه: فایل را بگیر، خبر بعدی را به نوار بفرست. مشترک میان NoticeWork و NoticeAlarm؛
     * synchronized چون هر دو ممکن است در یک دقیقه بیدار شوند. هرگز روی رشته‌ی اصلی صدا زده نشود.
     */
    @Synchronized
    fun check(c: Context) {
        val app = c.applicationContext
        if (!allowed(app)) return
        refreshNow(app)
        post(app)
        // خبری که «از ساعت فلان» است تا یک ربع بعد منتظر نمی‌ماند: آلارم سر همان ساعت بیدار می‌کند.
        NoticeAlarm.wakeAt(app, nextStart(app))
    }

    /**
     * کِی خبر بعدی باید به نوار برود (ساعت شروعش، یا پایان فاصله با قبلی)، به وقت دیواری؛ 0 یعنی چیزی
     * در راه نیست. خبر دیده‌شده یا به نوار رفته حساب نمی‌شود.
     */
    private fun nextStart(c: Context): Long {
        val prefs = flutter(c)
        val now = System.currentTimeMillis()
        val seen = lines(prefs, K_SEEN)
        val told = lines(prefs, K_TOLD)
        val gapEnd = prefs.getLong(K_TRAY_AT, 0L).let { if (it in 1..now) it + GAP_MS else 0L }
        var next = Long.MAX_VALUE
        for (n in parse(prefs.getString(K_CACHE, null))) {
            if (n.id in seen || n.id in told || (n.until in 1 until now)) continue
            val at = maxOf(n.from, gapEnd)
            if (at > now && (n.until <= 0 || at <= n.until)) next = minOf(next, at)
        }
        return if (next == Long.MAX_VALUE) 0L else next
    }

    /** فایل را می‌گیرد و اگر امضا بخواند و تازه باشد نگه می‌دارد. true یعنی چیزی عوض شد. */
    fun refreshNow(c: Context): Boolean {
        val address = url(c) ?: return false
        val publicKey = publicKey(c)
        if (publicKey == null) {
            note(c, "این نسخه کلید امضا ندارد — هیچ خبری نمایش داده نمی‌شود")
            return false
        }
        val raw: ByteArray? = try {
            // پرسش یکتا: هیچ میانجی نسخه‌ی کهنه‌ی فایل را تحویل نمی‌دهد.
            fetch(address + (if ('?' in address) "&" else "?") + "t=" + System.currentTimeMillis(), MAX_BYTES)
        } catch (_: Exception) {
            null
        }
        if (raw == null) {
            note(c, "فایل خبرها از سرور نیامد (notices.json)")
            return false
        }
        // امضا روی همان بایت‌هایی آزموده می‌شود که رسیده‌اند، نه روی متنی که دوباره ساخته شده.
        val bytes: ByteArray? = try {
            unseal(String(raw, Charsets.UTF_8), publicKey)
        } catch (_: Exception) {
            null
        }
        if (bytes == null) {
            note(c, "امضا با فایل نمی‌خواند — یا فایل دستی عوض شده، یا با کلید دیگری امضا شده")
            return false
        }
        val fresh = String(bytes, Charsets.UTF_8)
        val isList = try {
            JSONObject(fresh).optJSONArray("notices") != null
        } catch (_: Exception) {
            false
        }
        if (!isList) {
            note(c, "آنچه آمد فایل خبرها نبود")
            return false
        }
        val count = parse(fresh).size
        val prefs = flutter(c)
        if (fresh == prefs.getString(K_CACHE, null)) {
            note(c, "چیز تازه‌ای نبود (${fa(count)} خبر، همان‌ها)")
            return false
        }
        prefs.edit().putString(K_CACHE, fresh).apply()
        note(c, "${fa(count)} خبر گرفته شد")
        return true
    }

    /** «آخرین بررسی» در بخش والدین؛ همه‌ی شکست‌ها بی‌صدا هستند و این تنها نشانشان است. */
    private fun note(c: Context, what: String) {
        flutter(c).edit().putLong(K_CHECK, System.currentTimeMillis()).putString(K_RESULT, what).apply()
    }

    private fun parse(json: String?): List<Notice> {
        val out = ArrayList<Notice>()
        if (json.isNullOrEmpty()) return out
        try {
            val list = JSONObject(json).optJSONArray("notices") ?: return out
            for (i in 0 until list.length()) {
                val o = list.optJSONObject(i) ?: continue
                val id = o.optString("id").trim()
                val title = o.optString("title").trim()
                if (id.isEmpty() || title.isEmpty()) continue
                out.add(
                    Notice(
                        id, title, o.optString("body").trim(), o.optString("image").trim(),
                        o.optString("imageSha256").trim().lowercase(), o.optString("screen").trim(),
                        o.optLong("from", 0L), o.optLong("until", 0L),
                    ),
                )
            }
        } catch (_: Exception) {
            // فایل نیمه‌کاره ارزش خراب کردن برنامه‌ی کودک را ندارد.
        }
        return out
    }

    private fun lines(prefs: SharedPreferences, key: String): MutableSet<String> =
        (prefs.getString(key, "") ?: "").split('\n').filter { it.isNotEmpty() }.toMutableSet()

    /** نزدیک‌ترین مهلت اول؛ بی‌مهلت‌ها بعد، به ترتیب فایل (sortedBy پایدار است). */
    private fun byUrgency(list: List<Notice>) = list.sortedBy { if (it.until > 0) it.until else Long.MAX_VALUE }

    private fun pressing(n: Notice, now: Long) = n.until > 0 && n.until - now <= GAP_MS

    /** ساعتی که عقب کشیده شده خبرها را قفل نمی‌کند. */
    private fun spaced(last: Long, now: Long) = last <= 0 || last > now || now - last >= GAP_MS

    // ── نوار اعلان ───────────────────────────────────────────────────────────

    /**
     * فوری‌ترین خبری که هنوز به نوار نرفته — یکی، نه همه. بقیه در نوبت‌های بعد، هر کدام دست‌کم
     * [GAP_MS] بعد از قبلی. برداشته می‌شود تا هرگز دو بار به نوار نرود.
     */
    private fun claimNextForTray(c: Context): Notice? {
        val prefs = flutter(c)
        val all = parse(prefs.getString(K_CACHE, null))
        val now = System.currentTimeMillis()
        val seen = lines(prefs, K_SEEN)
        val told = lines(prefs, K_TOLD)
        // شناسه‌هایی که دیگر در فایل نیستند کنار می‌روند تا فهرست بی‌پایان بزرگ نشود.
        told.retainAll(all.map { it.id }.toSet())
        val gapOver = spaced(prefs.getLong(K_TRAY_AT, 0L), now)
        val next = byUrgency(all.filter { it.current(now) && it.id !in seen && it.id !in told })
            .firstOrNull { gapOver || pressing(it, now) }
        val edit = prefs.edit()
        if (next != null) {
            told.add(next.id)
            edit.putLong(K_TRAY_AT, now)
        }
        edit.putString(K_TOLD, told.joinToString("\n")).commit()
        return next
    }

    /** نرسید (اجازه درست پیش از نمایش پس گرفته شد): خبر و فاصله‌اش پس داده می‌شوند. */
    private fun unclaimForTray(c: Context, id: String) {
        val prefs = flutter(c)
        val told = lines(prefs, K_TOLD).apply { remove(id) }
        prefs.edit().putString(K_TOLD, told.joinToString("\n")).remove(K_TRAY_AT).apply()
    }

    /** یک خبر به نوار اعلان. روی رشته‌ی پس‌زمینه، چون تصویر شاید دانلود شود. */
    @Synchronized
    fun post(c: Context) {
        val app = c.applicationContext
        if (!allowed(app) || !permitted(app) || publicKey(app) == null) return
        ensureChannel(app)
        val n = claimNextForTray(app) ?: return

        // لمس اعلان برنامه را باز می‌کند: یا روی صفحه‌ای که خبر نشانش داده، یا روی خود خبر با عکس و
        // دکمه‌هایش. پیوند بیرونی فقط از داخل برنامه و پشت دروازه‌ی والدین باز می‌شود (برنامه‌ی کودک).
        val open = Intent(app, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(EXTRA_ID, n.id)
        if (n.destination.isNotEmpty()) open.putExtra(EXTRA_SCREEN, n.destination) else open.putExtra(EXTRA_SHOW, true)
        val tap = PendingIntent.getActivity(
            app, n.id.hashCode(), open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val built = NotificationCompat.Builder(app, CHANNEL)
            .setSmallIcon(R.drawable.ic_notice)
            .setContentTitle(n.title)
            .setContentText(n.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(n.body))
            .setAutoCancel(true)
            .setContentIntent(tap)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        // عکس فقط وقتی همان باشد که امضا شده؛ اگر نشد، متن تنها می‌رود.
        if (n.hasImage) {
            picture(app, n)?.let { bitmap ->
                built.setLargeIcon(bitmap).setStyle(
                    NotificationCompat.BigPictureStyle()
                        .bigPicture(bitmap)
                        .bigLargeIcon(null as Bitmap?)
                        .setSummaryText(n.body),
                )
            }
        }
        try {
            NotificationManagerCompat.from(app).notify(Math.abs(n.id.hashCode()), built.build())
        } catch (_: SecurityException) {
            unclaimForTray(app, n.id)
        }
    }

    private fun ensureChannel(c: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = c.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(CHANNEL, "خبرهای پوپو", NotificationManager.IMPORTANCE_DEFAULT)
        channel.description = "مرحله‌ها، بازی‌ها و صداهای تازه"
        manager.createNotificationChannel(channel)
    }

    /** تصویر خبر: روی گوشی نگه داشته می‌شود، با sha256 متن امضاشده سنجیده و در اندازه‌ی گوشی باز می‌شود. */
    private fun picture(c: Context, n: Notice): Bitmap? {
        val address = url(c) ?: return null
        if (n.image.contains("..") || n.image.startsWith("/") || n.image.contains("://")) return null
        val dir = File(c.filesDir, "notices").apply { mkdirs() }
        val file = File(dir, n.image.substringAfterLast('/'))
        return try {
            if (!file.exists() || sha256(file.readBytes()) != n.imageSha256) {
                val imageUrl = address.substringBeforeLast("/") + "/" + n.image
                val bytes = fetch(imageUrl, MAX_IMAGE) ?: return null
                if (sha256(bytes) != n.imageSha256) return null
                file.writeBytes(bytes)
            }
            val measure = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.absolutePath, measure)
            var sample = 1
            while (measure.outWidth / sample > WIDEST) sample *= 2
            BitmapFactory.decodeFile(file.absolutePath,
                BitmapFactory.Options().apply { inSampleSize = sample })
        } catch (_: Throwable) {
            null
        }
    }

    // ── امضا و شبکه ──────────────────────────────────────────────────────────

    /** کلید عمومی همراه برنامه؛ نبودنش (کلید هنوز ساخته نشده) یعنی «خبری نیست». */
    private fun publicKey(c: Context): PublicKey? {
        key?.let { return it }
        return try {
            val pem = c.assets.open(KEY_ASSET).use { String(it.readBytes(), Charsets.US_ASCII) }
            val b64 = pem.replace(Regex("-----[A-Z ]+-----"), "").replace(Regex("\\s"), "")
            val k = KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(Base64.decode(b64, Base64.DEFAULT)))
            if (k is RSAPublicKey && k.modulus.bitLength() >= 2048) k.also { key = it } else null
        } catch (_: Exception) {
            null
        }
    }

    /** همان پاکت lib/data/notice_seal.dart: {"alg":"RSA-SHA256","body":b64,"sig":b64}. */
    private fun unseal(envelope: String, publicKey: PublicKey): ByteArray? {
        val root = JSONObject(envelope)
        if (root.optString("alg") != "RSA-SHA256") return null
        val body = Base64.decode(root.getString("body"), Base64.DEFAULT)
        val sig = Base64.decode(root.getString("sig"), Base64.DEFAULT)
        if (body.isEmpty()) return null
        val v = Signature.getInstance("SHA256withRSA")
        v.initVerify(publicKey)
        v.update(body)
        return if (v.verify(sig)) body else null
    }

    private fun fetch(address: String, limit: Int): ByteArray? {
        val conn = URL(address).openConnection() as HttpURLConnection
        try {
            conn.connectTimeout = 20_000
            conn.readTimeout = 20_000
            conn.useCaches = false
            if (conn.responseCode != 200) return null
            val out = ByteArrayOutputStream()
            conn.inputStream.use { input ->
                val buf = ByteArray(8192)
                while (true) {
                    val n = input.read(buf)
                    if (n < 0) break
                    out.write(buf, 0, n)
                    if (out.size() > limit) return null
                }
            }
            return out.toByteArray()
        } finally {
            conn.disconnect()
        }
    }

    private fun sha256(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

    private fun fa(n: Int): String {
        val digits = "۰۱۲۳۴۵۶۷۸۹"
        return n.toString().map { if (it in '0'..'9') digits[it - '0'] else it }.joinToString("")
    }
}
