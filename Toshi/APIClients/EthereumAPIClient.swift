// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import Teapot

public class EthereumAPIClient: NSObject {

    static let shared: EthereumAPIClient = EthereumAPIClient()
    private static let collectionKey = "ethereumExchangeRate"

    public var exchangeRate: Decimal {
        updateRate()

        if let rate = Yap.sharedInstance.retrieveObject(for: EthereumAPIClient.collectionKey) as? Decimal {
            return rate
        } else {
            return 15.0
        }
    }

    fileprivate var exchangeTeapot: Teapot

    fileprivate var mainTeapot: Teapot

    fileprivate var switchedNetworkTeapot: Teapot

    fileprivate var activeTeapot: Teapot {
        if NetworkSwitcher.shared.isDefaultNetworkActive {
            return mainTeapot
        } else {
            return switchedNetworkTeapot
        }
    }

    fileprivate static var teapotUrl: String {
        return NetworkSwitcher.shared.activeNetworkBaseUrl
    }

    fileprivate override init() {
        mainTeapot = Teapot(baseURL: URL(string: NetworkSwitcher.shared.defaultNetworkBaseUrl)!)
        switchedNetworkTeapot = Teapot(baseURL: URL(string: NetworkSwitcher.shared.defaultNetworkBaseUrl)!)

        exchangeTeapot = Teapot(baseURL: URL(string: "https://api.coinbase.com")!)

        super.init()

        updateRate()
    }

    public func getRate(_ completion: @escaping ((_ rate: Decimal?) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.exchangeTeapot.get("/v2/exchange-rates?currency=ETH") { (result: NetworkResult) in
                switch result {
                case .success(let json, _):
                    guard let json = json?.dictionary,
                        let data = json["data"] as? [String: Any],
                        let rates = data["rates"] as? [String: Any],
                        let usd = rates["USD"] as? String,
                        let doubleValue = Double(usd) as Double? else {

                        completion(nil)
                        return
                    }

                    completion(Decimal(doubleValue))
                case .failure(_, let response, let error):
                    print(response)
                    print(error.localizedDescription)
                    completion(nil)
                }
            }
        }
    }

    public func createUnsignedTransaction(parameters: [String: Any], completion: @escaping ((_ unsignedTransaction: String?, _ error: Error?) -> Void)) {
        let json = RequestParameter(parameters)

        DispatchQueue.global(qos: .userInitiated).async {
            self.activeTeapot.post("/v1/tx/skel", parameters: json) { result in
                switch result {
                case .success(let json, let response):
                    print(response)
                    completion(json!.dictionary!["tx"] as? String, nil)
                case .failure(let json, let response, let error):
                    print(response)
                    print(json ?? "")
                    print(error)
                    completion(nil, error)
                }
            }
        }
    }

    public func sendSignedTransaction(originalTransaction: String, transactionSignature: String, completion: @escaping ((_ json: RequestParameter?, _ error: Error?) -> Void)) {
        timestamp(activeTeapot) { timestamp in
            let cereal = Cereal.shared
            let path = "/v1/tx"
            let params = [
                "tx": originalTransaction,
                "signature": transactionSignature
            ]

            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
            let hashedPayload = cereal.sha3WithWallet(string: payloadString)

            let signature = "0x\(cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let headers: [String: String] = [
                "Token-ID-Address": cereal.paymentAddress,
                "Token-Signature": signature,
                "Token-Timestamp": timestamp
            ]

            let json = RequestParameter(params)

            DispatchQueue.global(qos: .userInitiated).async {
                self.activeTeapot.post(path, parameters: json, headerFields: headers) { result in
                    switch result {
                    case .success(let json, let response):
                        print(response)
                        print(json ?? "")
                        completion(json, nil)
                    case .failure(let json, let response, let error):
                        print(response)
                        print(json ?? "")
                        print(error)
                        let json = RequestParameter((json!.dictionary!["errors"] as! [[String: Any]]).first!)
                        completion(json, error)
                    }
                }
            }
        }
    }

    public func getBalance(address: String, completion: @escaping ((_ balance: NSDecimalNumber, _ error: Error?) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.activeTeapot.get("/v1/balance/\(address)") { (result: NetworkResult) in
                switch result {
                case .success(let json, let response):
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "Could not fetch balance."])
                    guard response.statusCode == 200 else { completion(0, error); return }
                    guard let json = json?.dictionary else { completion(0, error); return }

                    let unconfirmedBalanceString = json["unconfirmed_balance"] as? String ?? "0"
                    let unconfirmedBalance = NSDecimalNumber(hexadecimalString: unconfirmedBalanceString)

                    TokenUser.current?.balance = unconfirmedBalance

                    completion(unconfirmedBalance, nil)
                case .failure(let json, let response, let error):
                    completion(0, error)
                    print(error)
                    print(response)
                    print(json ?? "")
                }
            }
        }
    }

    public func registerForMainNetworkPushNotifications() {
        timestamp(mainTeapot) { timestamp in
            self.registerForPushNotifications(timestamp, teapot: self.mainTeapot) { _ in
            }
        }
    }

    public func registerForSwitchedNetworkPushNotificationsIfNeeded(completion: ((Bool) -> Void)? = nil) {
        guard NetworkSwitcher.shared.isDefaultNetworkActive == false else {
            completion?(true)
            return
        }

        switchedNetworkTeapot.baseURL = URL(string: NetworkSwitcher.shared.activeNetworkBaseUrl)!

        timestamp(switchedNetworkTeapot) { timestamp in
            self.registerForPushNotifications(timestamp, teapot: self.switchedNetworkTeapot, completion: completion)
        }
    }

    public func deregisterFromMainNetworkPushNotifications() {
        timestamp(mainTeapot) { timestamp in
            self.deregisterFromPushNotifications(timestamp, teapot: self.mainTeapot)
        }
    }

    public func deregisterFromSwitchedNetworkPushNotifications(completion: ((Bool) -> Void)? = nil) {
        timestamp(switchedNetworkTeapot) { timestamp in
            self.deregisterFromPushNotifications(timestamp, teapot: self.switchedNetworkTeapot, completion: completion)
        }
    }

    fileprivate func updateRate() {
        getRate { rate in
            if rate != nil {
                Yap.sharedInstance.insert(object: rate, for: EthereumAPIClient.collectionKey)
            }
        }
    }

    fileprivate func timestamp(_ teapot: Teapot, _ completion: @escaping ((_ timestamp: String) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            teapot.get("/v1/timestamp") { (result: NetworkResult) in
                switch result {
                case .success(let json, _):
                    guard let json = json?.dictionary else { fatalError() }
                    guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp should be an integer") }

                    completion(String(timestamp))
                case .failure(_, _, let error):
                    print(error)
                }
            }
        }
    }

    fileprivate func registerForPushNotifications(_ timestamp: String, teapot: Teapot, completion: ((Bool) -> Void)? = nil) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let cereal = Cereal.shared
        let path = "/v1/apn/register"
        let address = cereal.address

        let params = ["registration_id": appDelegate.token, "address": cereal.paymentAddress]
        let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
        let hashedPayload = cereal.sha3WithID(string: payloadString)
        let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

        let headerFields: [String: String] = [
            "Token-ID-Address": address,
            "Token-Signature": signature,
            "Token-Timestamp": timestamp
        ]

        let json = RequestParameter(params)

        DispatchQueue.global(qos: .userInitiated).async {
            teapot.post(path, parameters: json, headerFields: headerFields) { result in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)

                    print("\n +++ Registered for :\(teapot.baseURL)")

                    completion?(true)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)

                    completion?(false)
                }
            }
        }
    }

    fileprivate func deregisterFromPushNotifications(_ timestamp: String, teapot: Teapot, completion: ((Bool) -> Void)? = nil) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let cereal = Cereal.shared
        let address = cereal.paymentAddress
        let path = "/v1/apn/deregister"

        let params = ["registration_id": appDelegate.token, "address": cereal.paymentAddress]

        let payloadString = String(data: try! JSONSerialization.data(withJSONObject: params, options: []), encoding: .utf8)!
        let hashedPayload = cereal.sha3WithWallet(string: payloadString)
        let signature = "0x\(cereal.signWithWallet(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

        let headerFields: [String: String] = [
            "Token-ID-Address": address,
            "Token-Signature": signature,
            "Token-Timestamp": timestamp
        ]

        let json = RequestParameter(params)

        DispatchQueue.global(qos: .userInitiated).async {
            teapot.post(path, parameters: json, headerFields: headerFields) { result in
                switch result {
                case .success(let json, let response):
                    print(json ?? "")
                    print(response)

                    print("\n --- DE-registered from :\(teapot.baseURL)")

                    completion?(true)
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)

                    completion?(false)
                }
            }
        }
    }
}
