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

import UIKit
import Teapot
import SweetFoundation

public struct RatingScore {
    public struct StarsCount {
        public static var zero: StarsCount {
            return StarsCount(one: 0, two: 0, three: 0, four: 0, five: 0)
        }

        let one: Int
        let two: Int
        let three: Int
        let four: Int
        let five: Int

        init?(_ json: [String: Int]) {
            guard let one = json["1"] else { return nil }
            guard let two = json["2"] else { return nil }
            guard let three = json["3"] else { return nil }
            guard let four = json["4"] else { return nil }
            guard let five = json["5"] else { return nil }

            self.init(one: one, two: two, three: three, four: four, five: five)
        }

        private init(one: Int, two: Int, three: Int, four: Int, five: Int) {
            self.one = one
            self.two = two
            self.three = three
            self.four = four
            self.five = five
        }
    }

    static var zero: RatingScore {
        return RatingScore(reputationScore: 0.0, averageRating: 0.0, reviewCount: 0, stars: StarsCount.zero)
    }

    let reputationScore: Double
    let averageRating: Double
    let reviewCount: Int

    let stars: StarsCount

    init?(json: [String: Any]) {
        guard let reputationScore = json["reputation_score"] as? Double else { return nil }
        guard let averageRating = json["average_rating"] as? Double else { return nil }
        guard let reviewCount = json["review_count"] as? Int else { return nil }
        guard let stars = json["stars"] as? [String: Int] else { return nil }
        guard let starsCount = StarsCount(stars) else { return nil }

        self.init(reputationScore: reputationScore, averageRating: averageRating, reviewCount: reviewCount, stars: starsCount)
    }

    private init(reputationScore: Double, averageRating: Double, reviewCount: Int, stars: StarsCount) {
        self.reputationScore = reputationScore
        self.averageRating = averageRating
        self.reviewCount = reviewCount
        self.stars = stars
    }
}

class RatingsClient: NSObject {
    public static let shared: RatingsClient = RatingsClient()

    public var teapot: Teapot

    public var baseURL: URL

    private override init() {
        baseURL = URL(string: TokenRatingsServiceBaseURLPath)!
        teapot = Teapot(baseURL: baseURL)

        super.init()
    }

    private func fetchTimestamp(_ completion: @escaping ((_ ratingScore: Int) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.teapot.get("/v1/timestamp") { (result: NetworkResult) in
                switch result {
                case .success(let json, _):
                    guard let json = json?.dictionary, let timestamp = json["timestamp"] as? Int else {
                        print("Invalid response - Fetch timestamp")
                        return
                    }

                    completion(timestamp)

                case .failure(_, let response, _):
                    print(response)
                }
            }
        }
    }

    public func submit(userId: String, rating: Int, review: String, completion: (() -> Void)? = nil) {
        fetchTimestamp { timestamp in
            let cereal = Cereal.shared
            let path = "/v1/review/submit"
            let payload: [String: Any] = [
                "rating": rating,
                "reviewee": userId,
                "review": review
            ]

            let payloadData = try! JSONSerialization.data(withJSONObject: payload, options: [])
            let payloadString = String(data: payloadData, encoding: .utf8)!
            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(describing: timestamp)]
            let json = RequestParameter(payload)

            DispatchQueue.global(qos: .userInitiated).async {
                self.teapot.post(path, parameters: json, headerFields: fields) { result in
                    switch result {
                    case .success:
                        let alert = UIAlertController(title: "Success", message: "User succesfully reviewed.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))

                        Navigator.presentModally(alert)
                        completion?()
                    case .failure(let json, _, _):
                        guard let json = json?.dictionary, let errors = json["errors"] as? [Any], let error = errors.first as? [String: Any], let message = error["message"] as? String else { return }

                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))

                        Navigator.presentModally(alert)
                        completion?()
                    }
                }
            }
        }
    }

    public func scores(for userId: String, completion: @escaping ((_ ratingScore: RatingScore) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.teapot.get("/v1/user/\(userId)") { result in
                switch result {
                case .success(let json, _):
                    guard let json = json?.dictionary else { return }
                    guard let ratingScore = RatingScore(json: json) else { return }

                    completion(ratingScore)
                case .failure:
                    completion(RatingScore.zero)
                }
            }
        }
    }
}
