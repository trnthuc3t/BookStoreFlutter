package com.pro.book

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import vn.zalopay.sdk.ZaloPaySDK
import vn.zalopay.sdk.Environment
import vn.zalopay.sdk.ZaloPayError
import vn.zalopay.sdk.listeners.PayOrderListener
import okhttp3.*
import java.io.IOException
import java.security.InvalidKeyException
import java.security.NoSuchAlgorithmException
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class ZaloPayMethodCallHandler : MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var activity: Activity
    private lateinit var channel: MethodChannel
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private const val CHANNEL_NAME = "zalopay_payment"
        private const val EVENT_CHANNEL_NAME = "zalopay_payment_events"
        private const val TAG = "ZaloPayHandler"
        
        // SANDBOX credentials for testing
        private const val ZALOPAY_APP_ID = 553
        private const val ZALOPAY_KEY1 = "9phuAOYhan4urywHTh0ndEXiV3pKHr5Q"
        private const val ZALOPAY_CREATE_URL = "https://sandbox.zalopay.com.vn/v001/tpe/createorder"
        
        // Deep link scheme for merchant app (NOT zalopay!)
        // This is YOUR app's deeplink that ZaloPay will callback to
        private const val DEEP_LINK_SCHEME = "bookstoreapp://app"
        
        private var transIdDefault = 1
    }

    fun attachToEngine(flutterEngine: FlutterEngine, activityContext: Context) {
        context = activityContext
        activity = activityContext as Activity
        
        // Setup method channel
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        // Setup event channel for payment results
        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
        
        // Initialize ZaloPay SDK for SANDBOX environment
        ZaloPaySDK.init(ZALOPAY_APP_ID, Environment.SANDBOX)
        Log.d(TAG, "✅ ZaloPay SDK initialized with SANDBOX (AppID: $ZALOPAY_APP_ID)")
    }

    fun detachFromEngine() {
        channel.setMethodCallHandler(null)
        eventSink = null
    }

    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
        Log.d(TAG, "Event channel listener attached")
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        Log.d(TAG, "Event channel listener cancelled")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "createOrder" -> createOrder(call, result)
            "launchZaloPay" -> launchZaloPay(call, result)
            "isZaloPayInstalled" -> isZaloPayInstalled(result)
            "queryOrderStatus" -> queryOrderStatus(call, result)
            "refundOrder" -> refundOrder(call, result)
            else -> result.notImplemented()
        }
    }

    private fun createOrder(call: MethodCall, result: Result) {
        Thread {
            try {
                val amount = call.argument<Int>("amount") ?: 0
                val description = call.argument<String>("description") ?: "Thanh toán đơn hàng"
                val orderId = call.argument<String>("orderId") ?: ""

                Log.d(TAG, "📦 Creating ZaloPay SANDBOX order: amount=$amount, orderId=$orderId")

                // Generate app transaction ID
                val appTime = System.currentTimeMillis()
                val appTransId = getAppTransId()

                // Prepare order data
                val embedData = "{}"
                val items = "[]"
                // DON'T use bankCode for sandbox - let SDK handle it
                // val bankCode = "zalopayapp" // This might force production app

                // Create MAC
                val dataToSign = "$ZALOPAY_APP_ID|$appTransId|BookStore_User|$amount|$appTime|$embedData|$items"
                val mac = hmacSha256(ZALOPAY_KEY1, dataToSign)

                Log.d(TAG, "🔐 MAC: $mac")

                // Call ZaloPay Create Order API
                val client = OkHttpClient.Builder()
                    .connectTimeout(10, TimeUnit.SECONDS)
                    .writeTimeout(10, TimeUnit.SECONDS)
                    .readTimeout(30, TimeUnit.SECONDS)
                    .build()

                val formBody = FormBody.Builder()
                    .add("appid", ZALOPAY_APP_ID.toString())
                    .add("appuser", "BookStore_User")
                    .add("apptime", appTime.toString())
                    .add("amount", amount.toString())
                    .add("apptransid", appTransId)
                    .add("embeddata", embedData)
                    .add("item", items)
                    // .add("bankcode", bankCode) // Remove this to use sandbox
                    .add("description", description)
                    .add("mac", mac)
                    .build()

                val request = Request.Builder()
                    .url(ZALOPAY_CREATE_URL)
                    .post(formBody)
                    .build()

                val response = client.newCall(request).execute()
                val responseBody = response.body?.string()

                Log.d(TAG, "📡 ZaloPay API Response: $responseBody")

                if (response.isSuccessful && responseBody != null) {
                    val jsonResponse = JSONObject(responseBody)
                    val returnCode = jsonResponse.getInt("returncode")

                    if (returnCode == 1) {
                        val zptranstoken = jsonResponse.getString("zptranstoken")
                        val orderUrl = jsonResponse.optString("orderurl", "")
                        
                        val resultMap = mapOf(
                            "return_code" to returnCode,
                            "return_message" to "success",
                            "zptranstoken" to zptranstoken,
                            "order_url" to orderUrl,
                            "apptransid" to appTransId
                        )

                        Log.d(TAG, "✅ SANDBOX Order created: zptranstoken=$zptranstoken")
                        activity.runOnUiThread {
                            result.success(resultMap)
                        }
                    } else {
                        val errorMessage = jsonResponse.optString("returnmessage", "Unknown error")
                        Log.e(TAG, "❌ ZaloPay API error: $errorMessage")
                        activity.runOnUiThread {
                            result.error("CREATE_ORDER_ERROR", errorMessage, null)
                        }
                    }
                } else {
                    Log.e(TAG, "❌ HTTP error: ${response.code}")
                    activity.runOnUiThread {
                        result.error("HTTP_ERROR", "HTTP ${response.code}: $responseBody", null)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Exception in createOrder", e)
                activity.runOnUiThread {
                    result.error("CREATE_ORDER_EXCEPTION", e.message, null)
                }
            }
        }.start()
    }

    private fun launchZaloPay(call: MethodCall, result: Result) {
        try {
            val zpTransToken = call.argument<String>("zpTransToken") ?: ""
            
            if (zpTransToken.isEmpty()) {
                result.error("INVALID_TOKEN", "zpTransToken is required", null)
                return
            }

            Log.d(TAG, "🚀 Launching ZaloPay SANDBOX with token: $zpTransToken")
            Log.d(TAG, "🔗 Merchant deep link (callback): $DEEP_LINK_SCHEME")
            
            // Launch ZaloPay app with SDK
            // The SDK will open ZaloPay SANDBOX because we initialized with Environment.SANDBOX
            // After payment, ZaloPay will callback to our app via DEEP_LINK_SCHEME
            ZaloPaySDK.getInstance().payOrder(
                activity,
                zpTransToken,
                DEEP_LINK_SCHEME,
                object : PayOrderListener {
                    override fun onPaymentSucceeded(
                        transactionId: String?,
                        transToken: String?,
                        appTransID: String?
                    ) {
                        Log.d(TAG, "✅ Payment succeeded: transId=$transactionId, appTransId=$appTransID")
                        
                        // Send event to Flutter via EventChannel
                        activity.runOnUiThread {
                            eventSink?.success(mapOf(
                                "status" to "success",
                                "errorCode" to 1,
                                "transactionId" to (transactionId ?: ""),
                                "transToken" to (transToken ?: ""),
                                "appTransID" to (appTransID ?: "")
                            ))
                            
                            // Also return to the original caller
                            result.success(mapOf(
                                "status" to "success",
                                "transactionId" to (transactionId ?: ""),
                                "transToken" to (transToken ?: ""),
                                "appTransID" to (appTransID ?: "")
                            ))
                        }
                    }

                    override fun onPaymentCanceled(zpTransToken: String?, appTransID: String?) {
                        Log.d(TAG, "⚠️ Payment canceled: appTransId=$appTransID")
                        
                        activity.runOnUiThread {
                            eventSink?.success(mapOf(
                                "status" to "canceled",
                                "errorCode" to 4,
                                "zpTransToken" to (zpTransToken ?: ""),
                                "appTransID" to (appTransID ?: "")
                            ))
                            
                            result.success(mapOf(
                                "status" to "canceled",
                                "zpTransToken" to (zpTransToken ?: ""),
                                "appTransID" to (appTransID ?: "")
                            ))
                        }
                    }

                    override fun onPaymentError(
                        zaloPayError: ZaloPayError?,
                        zpTransToken: String?,
                        appTransID: String?
                    ) {
                        Log.e(TAG, "❌ Payment error: ${zaloPayError?.toString()}, appTransId=$appTransID")
                        Log.e(TAG, "❌ Error code: ${zaloPayError?.name}, message: ${zaloPayError?.toString()}")
                        
                        activity.runOnUiThread {
                            eventSink?.success(mapOf(
                                "status" to "error",
                                "errorCode" to -1,
                                "error" to (zaloPayError?.toString() ?: "Unknown error"),
                                "zpTransToken" to (zpTransToken ?: ""),
                                "appTransID" to (appTransID ?: "")
                            ))
                            
                            result.error(
                                "PAYMENT_ERROR",
                                zaloPayError?.toString() ?: "Unknown error",
                                mapOf(
                                    "zpTransToken" to (zpTransToken ?: ""),
                                    "appTransID" to (appTransID ?: "")
                                )
                            )
                        }
                    }
                }
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception in launchZaloPay", e)
            result.error("LAUNCH_ERROR", e.message, null)
        }
    }

    private fun isZaloPayInstalled(result: Result) {
        try {
            // Check if ZaloPay app is installed
            // For sandbox, might need to check for sandbox app package
            val packageManager = activity.packageManager
            
            // Try checking for ZaloPay package (works for both production and sandbox)
            val isInstalled = try {
                packageManager.getPackageInfo("com.zing.zalo", 0)
                true
            } catch (e: Exception) {
                false
            }
            
            Log.d(TAG, "📱 ZaloPay app installed: $isInstalled")
            result.success(isInstalled)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking ZaloPay installation", e)
            result.error("CHECK_INSTALLED_ERROR", e.message, null)
        }
    }

    private fun queryOrderStatus(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    private fun refundOrder(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    // Helper methods
    private fun hmacSha256(key: String, data: String): String {
        try {
            val secretKey = SecretKeySpec(key.toByteArray(), "HmacSHA256")
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(secretKey)
            val hashBytes = mac.doFinal(data.toByteArray())
            return hashBytes.joinToString("") { "%02x".format(it) }
        } catch (e: NoSuchAlgorithmException) {
            throw RuntimeException("HmacSHA256 algorithm not found", e)
        } catch (e: InvalidKeyException) {
            throw RuntimeException("Invalid key for HmacSHA256", e)
        }
    }

    private fun getAppTransId(): String {
        if (transIdDefault >= 100000) {
            transIdDefault = 1
        }
        transIdDefault += 1
        val formatDateTime = SimpleDateFormat("yyMMdd_HHmmss", Locale.getDefault())
        val timeString = formatDateTime.format(Date())
        return String.format("%s%06d", timeString, transIdDefault)
    }

    // Handle deep link callback from MainActivity
    fun handleNewIntent(intent: Intent?) {
        ZaloPaySDK.getInstance().onResult(intent)
    }
}
