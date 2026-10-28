import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// امضای انتشار از android/key.properties خوانده می‌شود (در گیت نیست؛ نمونه: key.properties.example).
// اگر نباشد، نسخه‌ی release با کلید debug امضا می‌شود تا فقط برای آزمایش نصب شود.
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

// کلید RSA پرداخت بازار از android/services.properties (در گیت نیست؛ نمونه: services.properties.example).
// خالی بودنش ساخت را نمی‌شکند: پرداخت خطای «کلید نیست» می‌دهد و برنامه «بازار در دسترس نیست» نشان می‌دهد.
val serviceProperties = Properties().apply {
    val f = rootProject.file("services.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val bazaarRsa: String = serviceProperties.getProperty("bazaar.rsa", "").trim()

android {
    namespace = "com.pokpok.ir"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.pokpok.ir"
        // اندروید ۱۰ (API 29) به بالا.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["bazaarRsa"] = bazaarRsa
        // همه‌ی پردازنده‌ها: ARM ۳۲ و ۶۴ بیتی (تقریباً همه‌ی گوشی‌ها) و x86_64 (شبیه‌سازها و چند تبلت).
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // پرداخت درون‌برنامه‌ای کافه‌بازار (BazaarBilling.kt)، مستقیم و بی افزونه‌ی flutter_poolakey.
    implementation("com.github.cafebazaar.Poolakey:poolakey:2.2.0")
    implementation("androidx.activity:activity-ktx:1.9.3")
    // اعلان‌ها بدون هیچ سرویس پوشی: برنامه خودش فایل امضاشده‌ی خبرها را از سرور می‌خواند
    // (NoticeWork.kt هر ربع ساعت، NoticeAlarm.kt از میان Doze) و خبر تازه را در نوار اعلان می‌گذارد.
    implementation("androidx.work:work-runtime:2.9.1")
}
