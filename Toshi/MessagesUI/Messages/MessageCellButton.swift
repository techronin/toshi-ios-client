import Foundation
import UIKit
import TinyConstraints

class MessageCellButton: UIControl {

    var buttonModel: Message.MessageButtonModel? {
        didSet {
            if let buttonModel = self.buttonModel {
                self.verticalGuidesConstraints.forEach { guide in
                    guide.constant = 15
                }

                self.divider.backgroundColor = UIColor.black.withAlphaComponent(0.1)

                let color = (buttonModel.type == .approve) ? Theme.tintColor : Theme.darkTextColor

                self.icon.image = UIImage(named: buttonModel.icon)?.withRenderingMode(.alwaysTemplate)
                self.icon.tintColor = color

                self.titleLabel.text = buttonModel.title
                self.titleLabel.textColor = color
                self.titleLabel.font = (buttonModel.type == .approve) ? Theme.medium(size: 15) : Theme.regular(size: 15)
            } else {
                self.icon.image = nil
                self.titleLabel.text = nil
                self.verticalGuidesConstraints.forEach { guide in
                    guide.constant = 0
                }
                self.divider.backgroundColor = nil
            }
        }
    }

    let titleLabel = UILabel()

    lazy var icon: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center

        return view
    }()

    private let divider = UIView()

    private let verticalGuides = [UILayoutGuide(), UILayoutGuide()]

    private let horizontalCenter = UILayoutGuide()

    private lazy var verticalGuidesConstraints: [NSLayoutConstraint] = {
        self.verticalGuides.map { guide in
            guide.height(0, priority: .high)
        }
    }()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addLayoutGuide(self.horizontalCenter)
        self.horizontalCenter.centerX(to: self)
        
        for guide in self.verticalGuides {
            self.addLayoutGuide(guide)
            guide.left(to: self)
            guide.right(to: self)
        }
        
        self.verticalGuides[0].top(to: self)
        self.verticalGuides[0].bottomToTop(of: self.horizontalCenter)
        
        self.verticalGuides[1].topToBottom(of: self.horizontalCenter)
        self.verticalGuides[1].bottom(to: self)

        self.addSubview(self.icon)
        self.icon.top(to: self.horizontalCenter)
        self.icon.left(to: self.horizontalCenter)
        self.icon.bottom(to: self.horizontalCenter)

        self.addSubview(self.titleLabel)
        self.titleLabel.top(to: self.horizontalCenter)
        self.titleLabel.leftToRight(of: self.icon, offset: 5)
        self.titleLabel.bottom(to: self.horizontalCenter)
        self.titleLabel.right(to: self.horizontalCenter)

        self.addSubview(self.divider)
        self.divider.left(to: self)
        self.divider.top(to: self)
        self.divider.right(to: self)
        self.divider.height(1)
    }

    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = self.isHighlighted ? UIColor.black.withAlphaComponent(0.1) : nil
        }
    }
}
