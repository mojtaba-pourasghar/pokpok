package com.pokpok.ir

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * گذاشتن دوباره‌ی بررسی خبرها بعد از روشن شدن گوشی یا به‌روزرسانی برنامه.
 *
 * AlarmManager با هر روشن شدن دوباره (و هر به‌روزرسانی) همه چیز را فراموش می‌کند؛ WorkManager صف خودش
 * را در پایگاه‌داده نگه می‌دارد و نیازی به این ندارد، ولی زنجیره‌ی [NoticeAlarm] دارد.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED, "android.intent.action.QUICKBOOT_POWERON", Intent.ACTION_MY_PACKAGE_REPLACED -> Unit
            else -> return
        }
        // والدینی که خبرها را خاموش کرده‌اند، بعد از روشن شدن دوباره‌ی گوشی هم خاموش می‌مانند.
        if (NoticeCenter.allowed(context)) NoticeWork.schedule(context) else NoticeWork.cancel(context)
    }
}
