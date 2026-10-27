package com.pokpok.ir

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import java.util.concurrent.atomic.AtomicBoolean

/**
 * راه دوم دیدن خبرها وقتی برنامه بسته است — کنار [NoticeWork]، نه به جای آن.
 *
 * WorkManager به‌تنهایی کافی نبود: روی گوشی‌ای که در Doze است، یا برنامه‌ای که سیستم «کم‌استفاده»
 * دانسته (App Standby)، کار دوره‌ای از ربع ساعت به چند ساعت می‌رسد. آلارمی که با
 * setAndAllowWhileIdle گذاشته شود در Doze هم حدود هر نُه دقیقه اجازه می‌گیرد و در همان لحظه برنامه
 * کوتاه به اینترنت راه دارد؛ همان پنجره‌ای که بررسی لازم دارد.
 *
 * زنجیره است: هر آلارم پیش از هر کاری آلارم بعدی را می‌گذارد، پس بررسی‌ای که نیمه‌کاره بماند زنجیره
 * را نمی‌شکند. بررسی همین‌جا روی رشته‌ی خودش زیر goAsync انجام می‌شود، نه با سپردن به WorkManager —
 * کاری که از میان Doze در صف گذاشته شود منتظر همان پنجره‌ای می‌ماند که این برای دور زدنش است.
 */
class NoticeAlarm : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val app = context.applicationContext
        if (!NoticeCenter.allowed(app)) {
            cancel(app)
            return
        }
        // اول حلقه‌ی بعد: هر چه پایین پیش بیاید، زنجیره ادامه دارد.
        schedule(app)

        // broadcast پس‌زمینه حدود یک دقیقه وقت دارد؛ سرور کند نباید آن را «هنگ» نشان دهد، پس در
        // پنجاه ثانیه رها می‌شود (رشته شاید هنوز تمام کند).
        val result = goAsync()
        val done = AtomicBoolean(false)
        val finish = Runnable { if (done.compareAndSet(false, true)) result.finish() }
        Handler(Looper.getMainLooper()).postDelayed(finish, 50_000L)
        Thread({
            try {
                NoticeCenter.check(app)
            } catch (_: Exception) {
                // لحظه‌ی بد شبکه؛ آلارم بعدی دوباره امتحان می‌کند.
            } finally {
                finish.run()
            }
        }, "popo-notice-alarm").start()
    }

    companion object {
        private const val ACTION = "com.pokpok.ir.NOTICE_CHECK"
        private const val EVERY_MS = 15 * 60 * 1000L
        private const val REQUEST = 7402
        private const val DUE_AT = "noticeAlarmDueAt"
        /** چند ثانیه بعد از ساعت شروع، تا «حالا» در NoticeCenter بی‌شک از آن گذشته باشد. */
        private const val SLACK_MS = 3_000L

        private fun prefs(c: Context) = c.applicationContext.getSharedPreferences("popo_notice_alarm", Context.MODE_PRIVATE)

        private fun pending(c: Context, make: Boolean): PendingIntent? {
            val intent = Intent(c.applicationContext, NoticeAlarm::class.java).setAction(ACTION)
            val flags = PendingIntent.FLAG_IMMUTABLE or
                (if (make) PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_NO_CREATE)
            return PendingIntent.getBroadcast(c.applicationContext, REQUEST, intent, flags)
        }

        /**
         * زنجیره را روشن نگه می‌دارد، بی آن‌که آلارمی را که از قبل گذاشته شده عقب بیندازد — ده بار باز
         * کردن برنامه در ساعت نباید بررسی بعدی را مدام به تعویق بیندازد. نبود، دیر کرده (زنجیره شکسته:
         * توقف اجباری، به‌روزرسانی) یا مال پیش از روشن شدن دوباره‌ی گوشی: دوباره گذاشته می‌شود.
         */
        fun ensure(c: Context) {
            val due = prefs(c).getLong(DUE_AT, 0L)
            val now = SystemClock.elapsedRealtime()
            if (pending(c, false) == null || due <= 0 || due > now + EVERY_MS || now > due + EVERY_MS) schedule(c)
        }

        /** بررسی بعدی، یک ربع دیگر؛ جای هر آلارم قبلی را می‌گیرد. */
        fun schedule(c: Context) {
            val alarms = c.getSystemService(AlarmManager::class.java) ?: return
            val at = SystemClock.elapsedRealtime() + EVERY_MS
            try {
                alarms.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending(c, true)!!)
                prefs(c).edit().putLong(DUE_AT, at).apply()
            } catch (_: Exception) {
                // بعضی سازنده‌ها شمار آلارم‌ها را محدود می‌کنند؛ WorkManager هنوز نگاه می‌کند.
            }
        }

        /**
         * زودتر از نوبت معمول بیدار شو، سر [wallMs] (وقت دیواری): خبری که «از ساعت ۷» گذاشته شده نباید
         * تا یک ربع بعد منتظر بماند. فقط جلو می‌کشد، هرگز عقب نمی‌اندازد؛ بعد از آن زنجیره مثل همیشه هر
         * ربع ساعت ادامه دارد (onReceive اول [schedule] را صدا می‌زند). دقیق اگر سیستم اجازه بدهد، وگرنه
         * با همان setAndAllowWhileIdle که چند دقیقه‌ای شاید دیر کند.
         */
        fun wakeAt(c: Context, wallMs: Long) {
            if (wallMs <= 0) return
            val delay = wallMs - System.currentTimeMillis()
            if (delay <= 0) return
            val now = SystemClock.elapsedRealtime()
            val at = now + delay + SLACK_MS
            val due = prefs(c).getLong(DUE_AT, 0L)
            val chain = pending(c, false) != null && due > now
            if (chain && due <= at) return // نوبت معمول خودش زودتر است
            if (!chain && at > now + EVERY_MS) {
                schedule(c)
                return
            }
            val alarms = c.getSystemService(AlarmManager::class.java) ?: return
            try {
                val tap = pending(c, true)!!
                if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
                    alarms.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, tap)
                } else {
                    alarms.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, tap)
                }
                prefs(c).edit().putLong(DUE_AT, at).apply()
            } catch (_: Exception) {
                // آلارم قبلی سر جایش است؛ خبر در نوبت معمول می‌رسد.
            }
        }

        /** «خبرها خاموش» در بخش والدین. */
        fun cancel(c: Context) {
            val existing = pending(c, false) ?: return
            c.getSystemService(AlarmManager::class.java)?.cancel(existing)
            existing.cancel()
            prefs(c).edit().remove(DUE_AT).apply()
        }
    }
}
