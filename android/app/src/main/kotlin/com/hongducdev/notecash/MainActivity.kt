package com.hongducdev.notecash

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "notecash/notification_permission",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationListenerSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            },
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "notecash/installed_apps",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listInstalledApps" -> {
                    try {
                        val pm = applicationContext.packageManager
                        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)

                        val resultList = apps.mapNotNull { appInfo ->
                            val packageName = appInfo.packageName ?: return@mapNotNull null
                            if (packageName == applicationContext.packageName) return@mapNotNull null
                            val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                            val isUpdatedSystemApp = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                            if (isSystemApp || isUpdatedSystemApp) return@mapNotNull null
                            val label = pm.getApplicationLabel(appInfo).toString()
                            mapOf(
                                "packageName" to packageName,
                                "label" to label,
                            )
                        }.sortedBy { it["label"] as String }

                        result.success(resultList)
                    } catch (e: Exception) {
                        result.success(emptyList<Map<String, Any>>())
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
