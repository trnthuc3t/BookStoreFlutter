import Flutter
import UIKit

public class ZaloPayMethodCallHandler: NSObject, FlutterPlugin {
    private static let CHANNEL_NAME = "zalopay_payment"
    private static let ZALOPAY_APP_ID = "2553"
    private static let ZALOPAY_KEY1 = "PcY4iZIKFCXgYvW2Lihk3hH2o6IH2k"
    private static let ZALOPAY_CREATE_URL = "https://sb-openapi.zalopay.vn/v2/create"
    private static let ZALOPAY_QUERY_URL = "https://sb-openapi.zalopay.vn/v2/query"
    private static let ZALOPAY_REFUND_URL = "https://sb-openapi.zalopay.vn/v2/refund"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: registrar.messenger())
        let instance = ZaloPayMethodCallHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createOrder":
            createOrder(call: call, result: result)
        case "launchZaloPay":
            launchZaloPay(call: call, result: result)
        case "isZaloPayInstalled":
            isZaloPayInstalled(result: result)
        case "queryOrderStatus":
            queryOrderStatus(call: call, result: result)
        case "refundOrder":
            refundOrder(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func createOrder(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Int,
              let description = args["description"] as? String,
              let orderId = args["orderId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let appTime = Int64(Date().timeIntervalSince1970 * 1000)
        let appTransId = getDatePart() + "_" + String(generateRandomNumber())
        let embedData = "{}"
        let item = "[]"
        
        let dataToSign = "\(ZaloPayMethodCallHandler.ZALOPAY_APP_ID)|\(appTransId)|user123|\(amount)|\(appTime)|\(embedData)|\(item)"
        let mac = hmacSha256(key: ZaloPayMethodCallHandler.ZALOPAY_KEY1, data: dataToSign)
        
        // In a real implementation, you would make HTTP request here
        // For now, return mock data
        let response: [String: Any] = [
            "return_code": 1,
            "return_message": "success",
            "sub_return_code": 1,
            "sub_return_message": "success",
            "zp_trans_token": "mock_token_\(appTransId)",
            "order_url": "https://sb-openapi.zalopay.vn/pay/\(appTransId)"
        ]
        
        result(response)
    }
    
    private func launchZaloPay(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let orderUrl = args["orderUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        if let url = URL(string: orderUrl) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                result(true)
            } else {
                result(false)
            }
        } else {
            result(false)
        }
    }
    
    private func isZaloPayInstalled(result: @escaping FlutterResult) {
        if let url = URL(string: "zalopay://") {
            let canOpen = UIApplication.shared.canOpenURL(url)
            result(canOpen)
        } else {
            result(false)
        }
    }
    
    private func queryOrderStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let orderId = args["orderId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        // In a real implementation, you would make HTTP request here
        // For now, return mock data
        let response: [String: Any] = [
            "return_code": 1,
            "return_message": "success",
            "sub_return_code": 1,
            "sub_return_message": "success",
            "is_processing": false,
            "amount": 100000,
            "zp_trans_id": "mock_trans_\(orderId)"
        ]
        
        result(response)
    }
    
    private func refundOrder(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let orderId = args["orderId"] as? String,
              let amount = args["amount"] as? Int,
              let description = args["description"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        // In a real implementation, you would make HTTP request here
        // For now, return mock success
        result(true)
    }
    
    private func hmacSha256(key: String, data: String) -> String {
        let keyData = key.data(using: .utf8)!
        let messageData = data.data(using: .utf8)!
        
        let hmac = keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyBytes.count, messageBytes.baseAddress, messageBytes.count, nil)
            }
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyBytes.count, messageBytes.baseAddress, messageBytes.count, &digest)
            }
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func getDatePart() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        return formatter.string(from: Date())
    }
    
    private func generateRandomNumber() -> Int {
        return 100000 + Int(arc4random_uniform(900000))
    }
}
