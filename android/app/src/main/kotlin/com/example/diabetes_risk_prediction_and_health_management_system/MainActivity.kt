package com.example.diabetes_risk_prediction_and_health_management_system

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.diatrack/paypal"
    private var methodChannel: MethodChannel? = null
    private var pendingSubscriptionId: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startPayPalCheckout" -> {
                    val approvalUrl = call.argument<String>("approvalUrl")
                    val subscriptionId = call.argument<String>("subscriptionId")

                    if (approvalUrl != null && subscriptionId != null) {
                        pendingSubscriptionId = subscriptionId
                        startPayPalCheckout(approvalUrl)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Missing approvalUrl or subscriptionId", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startPayPalCheckout(approvalUrl: String) {
        try {
            // 使用 Chrome Custom Tabs 获得内嵌浏览器体验
            val builder = CustomTabsIntent.Builder()

            // 可选：自定义 Custom Tab 的外观
            // builder.setToolbarColor(ContextCompat.getColor(this, R.color.colorPrimary))
            // builder.setShowTitle(true)

            val customTabsIntent = builder.build()

            // 启动 Chrome Custom Tab
            customTabsIntent.launchUrl(this, Uri.parse(approvalUrl))

            println("PayPal checkout opened in Custom Tab: $approvalUrl")
        } catch (e: Exception) {
            println("Error launching PayPal checkout: ${e.message}")
            methodChannel?.invokeMethod("onPayPalError", mapOf("error" to e.message))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // 重要：更新 intent
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        // 处理从 Custom Tab 返回的情况
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val data: Uri? = intent?.data

        println("Handling intent with data: $data")

        if (data != null && data.scheme == "diatrack" && data.host == "payment") {
            println("Deep link detected - Scheme: ${data.scheme}, Host: ${data.host}, Path: ${data.path}")

            when (data.path) {
                "/paypal-success" -> {
                    println("PayPal success callback received")
                    val subscriptionId = pendingSubscriptionId
                    if (subscriptionId != null) {
                        println("Invoking onPayPalSuccess with subscriptionId: $subscriptionId")
                        methodChannel?.invokeMethod("onPayPalSuccess",
                            mapOf("subscriptionId" to subscriptionId)
                        )
                        pendingSubscriptionId = null
                    } else {
                        println("Warning: No pending subscription ID found")
                    }
                }
                "/paypal-cancel" -> {
                    println("PayPal cancel callback received")
                    methodChannel?.invokeMethod("onPayPalCancel", null)
                    pendingSubscriptionId = null
                }
                else -> {
                    println("Unknown path: ${data.path}")
                }
            }
        } else {
            println("Intent data does not match PayPal deep link pattern")
        }
    }
}