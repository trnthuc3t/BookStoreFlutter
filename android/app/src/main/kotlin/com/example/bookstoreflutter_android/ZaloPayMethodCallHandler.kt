package com.example.bookstoreflutter_android

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.security.MessageDigest
import java.util.*
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class ZaloPayMethodCallHandler : MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    companion object {
        private const val CHANNEL_NAME = "zalopay_payment"
        private const val ZALOPAY_PACKAGE = "com.zing.zalo"
        private const val ZALOPAY_APP_ID = "2553"
        private const val ZALOPAY_KEY1 = "PcY4iZIKFCXgYvW2Lihk3hH2o6IH2k"
        private const val ZALOPAY_CREATE_URL = "https://sb-openapi.zalopay.vn/v2/create"
        private const val ZALOPAY_QUERY_URL = "https://sb-openapi.zalopay.vn/v2/query"
        private const val ZALOPAY_REFUND_URL = "https://sb-openapi.zalopay.vn/v2/refund"
    }

    fun attachToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    fun detachFromEngine() {
        channel.setMethodCallHandler(null)
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
        try {
            val amount = call.argument<Int>("amount") ?: 0
            val description = call.argument<String>("description") ?: ""
            val orderId = call.argument<String>("orderId") ?: ""

            val appTime = System.currentTimeMillis()
            val appTransId = getDatePart() + "_" + generateRandomNumber()
            val embedData = "{}"
            val item = "[]"

            val dataToSign = "$ZALOPAY_APP_ID|$appTransId|user123|$amount|$appTime|$embedData|$item"
            val mac = hmacSha256(ZALOPAY_KEY1, dataToSign)

            val formData = mapOf(
                "appid" to ZALOPAY_APP_ID,
                "appuser" to "user123",
                "apptime" to appTime.toString(),
                "amount" to amount.toString(),
                "apptransid" to appTransId,
                "embeddata" to embedData,
                "item" to item,
                "mac" to mac
            )

            // In a real implementation, you would make HTTP request here
            // For now, return mock data
            val response = mapOf(
                "return_code" to 1,
                "return_message" to "success",
                "sub_return_code" to 1,
                "sub_return_message" to "success",
                "zp_trans_token" to "mock_token_$appTransId",
                "order_url" to "https://sb-openapi.zalopay.vn/pay/$appTransId"
            )

            result.success(response)
        } catch (e: Exception) {
            result.error("CREATE_ORDER_ERROR", e.message, null)
        }
    }

    private fun launchZaloPay(call: MethodCall, result: Result) {
        try {
            val orderUrl = call.argument<String>("orderUrl") ?: ""
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(orderUrl))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", e.message, null)
        }
    }

    private fun isZaloPayInstalled(result: Result) {
        try {
            val packageManager = context.packageManager
            val isInstalled = try {
                packageManager.getPackageInfo(ZALOPAY_PACKAGE, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
            result.success(isInstalled)
        } catch (e: Exception) {
            result.error("CHECK_INSTALLED_ERROR", e.message, null)
        }
    }

    private fun queryOrderStatus(call: MethodCall, result: Result) {
        try {
            val orderId = call.argument<String>("orderId") ?: ""
            
            // In a real implementation, you would make HTTP request here
            // For now, return mock data
            val response = mapOf(
                "return_code" to 1,
                "return_message" to "success",
                "sub_return_code" to 1,
                "sub_return_message" to "success",
                "is_processing" to false,
                "amount" to 100000,
                "zp_trans_id" to "mock_trans_$orderId"
            )

            result.success(response)
        } catch (e: Exception) {
            result.error("QUERY_ORDER_ERROR", e.message, null)
        }
    }

    private fun refundOrder(call: MethodCall, result: Result) {
        try {
            val orderId = call.argument<String>("orderId") ?: ""
            val amount = call.argument<Int>("amount") ?: 0
            val description = call.argument<String>("description") ?: ""

            // In a real implementation, you would make HTTP request here
            // For now, return mock success
            result.success(true)
        } catch (e: Exception) {
            result.error("REFUND_ERROR", e.message, null)
        }
    }

    private fun hmacSha256(key: String, data: String): String {
        val secretKey = SecretKeySpec(key.toByteArray(), "HmacSHA256")
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(secretKey)
        val hashBytes = mac.doFinal(data.toByteArray())
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    private fun getDatePart(): String {
        val calendar = Calendar.getInstance()
        val year = calendar.get(Calendar.YEAR).toString().substring(2)
        val month = (calendar.get(Calendar.MONTH) + 1).toString().padStart(2, '0')
        val day = calendar.get(Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
        return "$year$month$day"
    }

    private fun generateRandomNumber(): Int {
        return 100000 + (System.currentTimeMillis() % 900000).toInt()
    }
}
