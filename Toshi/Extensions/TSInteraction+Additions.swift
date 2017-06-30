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

private var stateAssociationKey: UInt8 = 0

extension TSInteraction {

    public enum PaymentState: Int {
        case none
        case failed
        case rejected
        case approved
    }

    public var paymentStateRaw: Int {
        get {
            return objc_getAssociatedObject(self, &stateAssociationKey) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(self, &stateAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    public var paymentState: PaymentState {
        get {
            return PaymentState(rawValue: self.paymentStateRaw)!
        }
        set {
            self.paymentStateRaw = newValue.rawValue
        }
    }
}
