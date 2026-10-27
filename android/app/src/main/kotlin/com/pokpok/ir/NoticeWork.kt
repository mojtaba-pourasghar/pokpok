package com.pokpok.ir

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * دیدن خبرها وقتی برنامه بسته است — همان کاری که یک سرویس پوش می‌کرد، بی SDK، بی حساب و بی شخص سوم:
 * سیستم گاه‌به‌گاه برنامه را بیدار می‌کند، همان فایل کوچک امضاشده خوانده می‌شود و خبر تازه به نوار
 * اعلان می‌رود ([NoticeCenter.check]).
 *
 * پانزده دقیقه کف است، و کف اندروید است نه عددی که این‌جا انتخاب شده: PeriodicWorkRequest کمتر از آن
 * را نمی‌پذیرد و در Doze حتی همان هم در پنجره‌های نگهداری سیستم جمع می‌شود. برای همین [NoticeAlarm]
 * کنارش هست. فقط با اینترنت اجرا می‌شود؛ بعد از روشن شدن دوباره‌ی گوشی WorkManager خودش ادامه می‌دهد.
 */
class NoticeWork(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        val app = applicationContext
        if (!NoticeCenter.allowed(app)) return Result.success()
        // زنجیره‌ی آلارم سریع‌تر است؛ هر بار که این اجرا شد، جای خوبی است که مطمئن شویم هنوز هست
        // (به‌روزرسانی یا توقف اجباری آلارم‌ها را پاک می‌کند، نه این صف را).
        NoticeAlarm.ensure(app)
        try {
            NoticeCenter.check(app)
        } catch (_: Exception) {
            // شبکه، امضا یا فایل خراب: نوبت بعد.
        }
        return Result.success()
    }

    companion object {
        private const val NAME = "popo-notices"
        private const val EVERY_MINUTES = 15L // کمترین مقداری که اندروید می‌پذیرد

        private val online = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

        /** بی‌خطر در هر بار باز شدن برنامه؛ چیزی را از نو نمی‌سازد. */
        fun schedule(context: Context) {
            val app = context.applicationContext
            try {
                val work = PeriodicWorkRequestBuilder<NoticeWork>(EVERY_MINUTES, TimeUnit.MINUTES)
                    .setConstraints(online)
                    .setBackoffCriteria(BackoffPolicy.LINEAR, 5, TimeUnit.MINUTES)
                    .build()
                // UPDATE نه KEEP: نسخه‌ای که با دوره‌ی شش‌ساعته نصب شده بود، تا ابد همان را نگه می‌داشت.
                WorkManager.getInstance(app).enqueueUniquePeriodicWork(NAME, ExistingPeriodicWorkPolicy.UPDATE, work)
            } catch (_: Exception) {
                // WorkManager بالا نیامد؛ بررسی‌های داخل برنامه و آلارم هنوز کار می‌کنند.
            }
            NoticeAlarm.ensure(app)
        }

        /** «خبرها خاموش» وقتی برنامه بسته است. */
        fun cancel(context: Context) {
            val app = context.applicationContext
            NoticeAlarm.cancel(app)
            try {
                WorkManager.getInstance(app).cancelUniqueWork(NAME)
                WorkManager.getInstance(app).cancelUniqueWork("$NAME-now")
            } catch (_: Exception) {
                // چیزی در صف نبود.
            }
        }

        /**
         * یک بار، همین حالا — وقتی برنامه بسته می‌شود. کودکی که همین الان گوشی را گذاشته به احتمال زیاد
         * هنوز نزدیک آن است. یکتا و جایگزین‌شونده: onPause با هر چرخش صفحه هم می‌آید.
         */
        fun once(context: Context) {
            val app = context.applicationContext
            if (!NoticeCenter.allowed(app)) return
            try {
                WorkManager.getInstance(app).enqueueUniqueWork(
                    "$NAME-now",
                    ExistingWorkPolicy.REPLACE,
                    OneTimeWorkRequestBuilder<NoticeWork>().setConstraints(online).build(),
                )
            } catch (_: Exception) {
                // بررسی دوره‌ای هنوز هست.
            }
        }
    }
}
