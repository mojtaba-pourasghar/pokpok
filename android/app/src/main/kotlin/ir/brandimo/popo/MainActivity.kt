package ir.brandimo.popo

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // فضای آزاد حافظه‌ی برنامه برای صفحه‌ی دانلودها (lib/core/assets/storage_info.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ir.brandimo.popo/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "freeBytes" -> result.success(StatFs(filesDir.path).availableBytes)
                    else -> result.notImplemented()
                }
            }
    }
}
