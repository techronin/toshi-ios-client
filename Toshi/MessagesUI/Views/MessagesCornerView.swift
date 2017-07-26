import Foundation
import UIKit

enum MessagesCornerType {
    case cornerBottomOutgoing
    case cornerBottomOutlineOutgoing
    case cornerBottomOutline
    case cornerBottom
    case cornerMiddleOutgoing
    case cornerMiddleOutlineOutgoing
    case cornerMiddleOutline
    case cornerMiddle
    case cornerTopOutgoing
    case cornerTopOutlineOutgoing
    case cornerTopOutline
    case cornerTop
}

class MessagesCornerView: UIImageView {

    private lazy var cornerBottomOutgoingImage: UIImage? = self.stretchableImage(with: "corner-bottom-outgoing")
    private lazy var cornerBottomOutlineOutgoingImage: UIImage? = self.stretchableImage(with: "corner-bottom-outline-outgoing")
    private lazy var cornerBottomOutlineImage: UIImage? = self.stretchableImage(with: "corner-bottom-outline")
    private lazy var cornerBottomImage: UIImage? = self.stretchableImage(with: "corner-bottom")
    private lazy var cornerMiddleOutgoingImage: UIImage? = self.stretchableImage(with: "corner-middle-outgoing")
    private lazy var cornerMiddleOutlineOutgoingImage: UIImage? = self.stretchableImage(with: "corner-middle-outline-outgoing")
    private lazy var cornerMiddleOutlineImage: UIImage? = self.stretchableImage(with: "corner-middle-outline")
    private lazy var cornerMiddleImage: UIImage? = self.stretchableImage(with: "corner-middle")
    private lazy var cornerTopOutgoingImage: UIImage? = self.stretchableImage(with: "corner-top-outgoing")
    private lazy var cornerTopOutlineOutgoingImage: UIImage? = self.stretchableImage(with: "corner-top-outline-outgoing")
    private lazy var cornerTopOutlineImage: UIImage? = self.stretchableImage(with: "corner-top-outline")
    private lazy var cornerTopImage: UIImage? = self.stretchableImage(with: "corner-top")

    var type: MessagesCornerType? {
        didSet {
            guard let type = type else {
                image = nil
                return
            }

            switch type {
            case .cornerBottomOutgoing:
                image = cornerBottomOutgoingImage
            case .cornerBottomOutlineOutgoing:
                image = cornerBottomOutlineOutgoingImage
            case .cornerBottomOutline:
                image = cornerBottomOutlineImage
            case .cornerBottom:
                image = cornerBottomImage
            case .cornerMiddleOutgoing:
                image = cornerMiddleOutgoingImage
            case .cornerMiddleOutlineOutgoing:
                image = cornerMiddleOutlineOutgoingImage
            case .cornerMiddleOutline:
                image = cornerMiddleOutlineImage
            case .cornerMiddle:
                image = cornerMiddleImage
            case .cornerTopOutgoing:
                image = cornerTopOutgoingImage
            case .cornerTopOutlineOutgoing:
                image = cornerTopOutlineOutgoingImage
            case .cornerTopOutline:
                image = cornerTopOutlineImage
            case .cornerTop:
                image = cornerTopImage
            }
        }
    }

    func stretchableImage(with name: String) -> UIImage? {
        return UIImage(named: name)?.stretchableImage(withLeftCapWidth: 18, topCapHeight: 18)
    }

    func setImage(for positionType: MessagePositionType, isOutGoing: Bool, isPayment: Bool) {

        if isPayment {
            switch positionType {
            case .top:
                type = isOutGoing ? .cornerTopOutlineOutgoing : .cornerTopOutline
            case .middle:
                type = isOutGoing ? .cornerMiddleOutlineOutgoing : .cornerMiddleOutline
            case .bottom:
                type = isOutGoing ? .cornerBottomOutlineOutgoing : .cornerBottomOutline
            }
        } else {
            switch positionType {
            case .top:
                type = isOutGoing ? .cornerTopOutgoing : .cornerTop
            case .middle:
                type = isOutGoing ? .cornerMiddleOutgoing : .cornerMiddle
            case .bottom:
                type = isOutGoing ? .cornerBottomOutgoing : .cornerBottom
            }
        }
    }
}
