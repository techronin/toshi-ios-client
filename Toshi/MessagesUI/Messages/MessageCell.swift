import UIKit

protocol MessageCellDelegate {
    func didTapImage(in cell: MessageCell)
    func didTapRejectButton(_ cell: MessageCell)
    func didTapApproveButton(_ cell: MessageCell)
}

class MessageCell: UICollectionViewCell {

    var delegate: MessageCellDelegate?

    var indexPath: IndexPath?

    private var linkTintColor: UIColor {
        return (self.message?.isOutgoing == true ? Theme.outgoingMessageTextColor : Theme.tintColor)
    }

    static var reuseIdentifier = "MessageCell"

    var titleFont: UIFont = Theme.regular(size: 18)

    var subtitleFont: UIFont = Theme.regular(size: 14)

    var statusFont: UIFont = Theme.regular(size: 13)

    let totalHorizontalMargin: CGFloat = 120

    var textFont: UIFont {
        guard let message = self.message else { return Theme.regular(size: 17) }

        if message.type == .paymentRequest || message.type == .payment {
            return Theme.regular(size: 14)
        }

        if message.text.hasEmojiOnly && message.text.characters.count < 4 {
            return Theme.regular(size: 50)
        }

        return Theme.regular(size: 17)
    }

    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = self.titleFont

        view.setCompressionResistance(.high, for: .vertical)
        view.setCompressionResistance(.high, for: .horizontal)

        return view
    }()

    lazy var textView: UITextView = {
        let view = UITextView()

        view.font = self.textFont
        view.dataDetectorTypes = [.link]
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = false
        view.backgroundColor = .clear
        view.contentMode = .topLeft
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.maximumNumberOfLines = 0

        view.setCompressionResistance(.high, for: .vertical)
        view.setCompressionResistance(.high, for: .horizontal)

        return view
    }()

    lazy var subtitleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = self.subtitleFont
        view.textColor = Theme.tintColor

        view.setCompressionResistance(.high, for: .vertical)
        view.setCompressionResistance(.high, for: .horizontal)

        return view
    }()

    lazy var imageView: MessageImageView = {
        let view = MessageImageView(frame: .zero)
        view.imageTap = {
            guard let indexPath = self.indexPath else { return }
            self.delegate?.didTapImage(in: self)
        }

        return view
    }()

    private let container: UIView = {
        let view = UIView()
        view.setHugging(.high, for: .vertical)
        view.setCompressionResistance(.high, for: .horizontal)
        
        return view
    }()

    private let avatar = UIImageView()
    
    private let usernameDetector = try! NSRegularExpression(pattern: " ?(@[a-zA-Z][a-zA-Z0-9_]{2,59}) ?", options: [.caseInsensitive, .useUnicodeWordBoundaries])

    private lazy var avatarLeft: NSLayoutConstraint = {
        self.avatar.centerX(to: self.leftSpacing, isActive: false)
    }()

    private lazy var avatarRight: NSLayoutConstraint = {
        self.avatar.centerX(to: self.rightSpacing, isActive: false)
    }()

    private lazy var verticalGuides: [UILayoutGuide] = {
        [UILayoutGuide(), UILayoutGuide(), UILayoutGuide(), UILayoutGuide()]
    }()

    private lazy var verticalGuidesConstraints: [NSLayoutConstraint] = {
        self.verticalGuides.map { guide in
            guide.height(0, priority: .high)
        }
    }()
    
    private lazy var textViewHeightConstraint: NSLayoutConstraint = {
        self.textView.height(0, priority: .high, isActive: false)
    }()
    
    private lazy var textLeftConstraints: NSLayoutConstraint = {
        self.textView.left(to: self.container, offset: self.horizontalMargin, isActive: false)
    }()

    private lazy var textRightConstraints: NSLayoutConstraint = {
        self.textView.right(to: self.container, offset: -self.horizontalMargin, isActive: false)
    }()

    private lazy var buttons: [MessageCellButton] = {
        [MessageCellButton(), MessageCellButton()]
    }()
    
    private lazy var paymentStatusLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.mediumTextColor
        label.font = UIFont.systemFont(ofSize: 14)
        
        return label
    }()

    private lazy var leftSpacing = UILayoutGuide()
    private lazy var rightSpacing = UILayoutGuide()

    private lazy var leftWidthSmall: NSLayoutConstraint = self.leftSpacing.width(10, relation: .equal, isActive: false)
    private lazy var rightWidthSmall: NSLayoutConstraint = self.rightSpacing.width(10, relation: .equal, isActive: false)
    private lazy var leftWidthBig: NSLayoutConstraint = self.leftSpacing.width(60, relation: .equalOrGreater, isActive: false)
    private lazy var rightWidthBig: NSLayoutConstraint = self.rightSpacing.width(60, relation: .equalOrGreater, isActive: false)

    private let horizontalMargin: CGFloat = 15

    var message: Message? {
        didSet {
            guard let message = self.message else { return }

            let shouldShowButtons = (message.signalMessage.paymentState == .none)
            
            if message.isActionable && shouldShowButtons  {
                for (index, model) in message.buttons.enumerated() {
                    if self.buttons.count > index {
                        self.buttons[index].buttonModel = model
                    }
                }
            } else {
                for button in self.buttons {
                    button.buttonModel = nil
                }
            }

            if let image = message.image {
                self.imageView.image = image
            } else {
                self.imageView.image = nil
            }

            self.titleLabel.text = message.title
            self.textView.text = message.text
            self.textView.font = self.textFont
            self.subtitleLabel.text = message.subtitle
            
            self.container.backgroundColor = message.isOutgoing ? Theme.outgoingMessageBackgroundColor : Theme.incomingMessageBackgroundColor
            self.titleLabel.textColor = message.isOutgoing ? Theme.lightTextColor : Theme.darkTextColor
            self.textView.textColor = message.isOutgoing ? Theme.lightTextColor : Theme.darkTextColor

            if message.isOutgoing {
                self.avatarLeft.isActive = false
                self.avatarRight.isActive = true

                self.leftWidthSmall.isActive = false
                self.rightWidthBig.isActive = false
                self.leftWidthBig.isActive = true
                self.rightWidthSmall.isActive = true
            } else {
                self.avatarRight.isActive = false
                self.avatarLeft.isActive = true

                self.leftWidthBig.isActive = false
                self.rightWidthSmall.isActive = false
                self.leftWidthSmall.isActive = true
                self.rightWidthBig.isActive = true
            }

            if message.text.isEmpty {
                self.textViewHeightConstraint.isActive = false
            } else {
                self.textViewHeightConstraint.isActive = true
            }

            if message.type == .paymentRequest || message.type == .payment {
                self.verticalGuidesConstraints[0].constant = 10
                self.verticalGuidesConstraints[1].constant = 5

                self.verticalGuidesConstraints[2].constant = message.text.isEmpty ? 0 : 10

                self.verticalGuidesConstraints[3].constant = 10

                self.container.backgroundColor = .white

                self.titleLabel.textColor = Theme.tintColor
                self.subtitleLabel.textColor = Theme.mediumTextColor
                self.textView.textColor = Theme.darkTextColor
                
                self.container.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
                self.container.layer.borderWidth = 1
                self.container.layer.cornerRadius = 16
            } else {
                self.verticalGuidesConstraints[0].constant = 0
                self.verticalGuidesConstraints[1].constant = 0
                self.verticalGuidesConstraints[2].constant = message.imageOnly ? 0 : 10
                self.verticalGuidesConstraints[3].constant = message.imageOnly ? 0 : 10

                self.container.layer.borderColor = nil
                self.container.layer.borderWidth = 0
                self.container.layer.cornerRadius = 6
            }

            if message.text.hasEmojiOnly, message.text.characters.count < 4 {
                if message.image == nil {
                    self.container.backgroundColor = nil
                }

                self.textLeftConstraints.constant = 0
                self.textRightConstraints.constant = 0
                self.verticalGuidesConstraints[2].constant = 0
                self.verticalGuidesConstraints[3].constant = 0
            } else {
                self.textLeftConstraints.constant = horizontalMargin
                self.textRightConstraints.constant = -self.horizontalMargin
            }

            self.avatar.image = UIImage(named: "Avatar")
            
            if let title = titleLabel.text, !title.isEmpty {
                self.verticalGuidesConstraints[0].constant = 10
            }
            
            self.applyCornersRadius()

            if !self.frame.isEmpty {
                self.detectUsernameLinks()
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }

            if message.image != nil {
                let maxWidth = UIScreen.main.bounds.width - self.totalHorizontalMargin
                let maxHeight: CGFloat = 200

                let imageWidth = self.imageSize(for: CGSize(width: maxWidth, height: maxHeight)).width
                self.imageView.widthConstraint?.isActive = true
                self.imageView.widthConstraint?.constant = imageWidth

                if message.imageOnly {
                    self.container.backgroundColor = nil
                }
            } else {
                self.imageView.widthConstraint?.isActive = false
            }
            
            switch message.signalMessage.paymentState {
            case .rejected:
                self.paymentStatusLabel.text = "Rejected"
            case .approved:
                self.paymentStatusLabel.text = "Approved"
            case .failed:
                self.paymentStatusLabel.text = "Failed"
            default:
                self.paymentStatusLabel.text = nil
            }
            
            if self.paymentStatusLabel.text != nil {
                self.verticalGuidesConstraints[3].constant = 40
                self.imageView.heightConstraint?.isActive = true
            } else {
                self.imageView.heightConstraint?.isActive = false
            }
            
            if !self.frame.isEmpty {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }

            self.textView.linkTextAttributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue, NSForegroundColorAttributeName: self.linkTintColor]
        }
    }

    required init?(coder _: NSCoder) { fatalError() }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.isOpaque = false

        self.addSubviewsAndConstraints()
    }

    private func addSubviewsAndConstraints() {
        self.contentView.addLayoutGuide(self.leftSpacing)
        self.leftSpacing.top(to: self.contentView)
        self.leftSpacing.left(to: self.contentView, offset: 10)
        self.leftSpacing.bottom(to: self.contentView)

        self.contentView.addLayoutGuide(self.rightSpacing)
        self.rightSpacing.top(to: self.contentView)
        self.rightSpacing.right(to: self.contentView, offset: -10)
        self.rightSpacing.bottom(to: self.contentView)

        self.leftWidthSmall.isActive = false
        self.rightWidthBig.isActive = false
        self.leftWidthBig.isActive = true
        self.rightWidthSmall.isActive = true

        self.contentView.addSubview(self.container)
        self.container.top(to: self.contentView)
        self.container.leftToRight(of: self.leftSpacing)
        self.container.bottom(to: self.contentView)
        self.container.rightToLeft(of: self.rightSpacing)

        self.contentView.addSubview(self.avatar)
        self.avatar.size(CGSize(width: 32, height: 32))
        self.avatar.bottom(to: self.contentView)
        self.avatarLeft.isActive = true

        self.container.addSubview(self.imageView)
        self.imageView.top(to: self.container)
        self.imageView.left(to: self.container)
        self.imageView.right(to: self.container)

        self.container.addSubview(self.titleLabel)
        self.titleLabel.left(to: self.container, offset: self.horizontalMargin)
        self.titleLabel.right(to: self.container, offset: -self.horizontalMargin)

        self.container.addSubview(self.textView)
        self.textLeftConstraints.isActive = true
        self.textRightConstraints.isActive = true

        self.container.addSubview(self.subtitleLabel)
        self.subtitleLabel.left(to: self.container, offset: self.horizontalMargin)
        self.subtitleLabel.right(to: self.container, offset: -self.horizontalMargin)

        for button in self.buttons {
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            self.container.addSubview(button)
            button.left(to: self.container)
            button.right(to: self.container)
        }

        for guide in self.verticalGuides {
            self.container.addLayoutGuide(guide)
            guide.left(to: self.container)
            guide.right(to: self.container)
        }
        
        self.buttons[0].bottomToTop(of: self.buttons[1])
        self.buttons[1].bottom(to: self.container)
        
        self.container.addSubview(self.paymentStatusLabel)
        self.paymentStatusLabel.height(40)
        self.paymentStatusLabel.left(to: self.container, offset: 16)
        self.paymentStatusLabel.right(to: self.container, offset: -16)
        self.paymentStatusLabel.bottom(to: self.container)

        self.verticalGuides[0].topToBottom(of: self.imageView)
        self.verticalGuides[0].bottomToTop(of: self.titleLabel)
        self.verticalGuides[1].topToBottom(of: self.titleLabel)
        self.verticalGuides[1].bottomToTop(of: self.subtitleLabel)
        self.verticalGuides[2].topToBottom(of: self.subtitleLabel)
        self.verticalGuides[2].bottomToTop(of: self.textView)
        self.verticalGuides[3].topToBottom(of: self.textView)
        self.verticalGuides[3].bottomToTop(of: self.buttons[0])
    }

    func buttonPressed(_ button: MessageCellButton) {
        guard let model = button.buttonModel else { return }

        switch model.type {
        case .approve:
            self.delegate?.didTapApproveButton(self)
        case .decline:
            self.delegate?.didTapRejectButton(self)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        self.applyCornersRadius()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    private func detectUsernameLinks() {
        if let text = self.textView.attributedText?.mutableCopy() as? NSMutableAttributedString {

            let range = NSRange(location: 0, length: text.string.length)

            self.usernameDetector.enumerateMatches(in: text.string, options: [], range: range) { result, _, _ in

                if let result = result {
                    let attrs: [String: Any] = [
                        NSLinkAttributeName: "toshi://username:\((text.string as NSString).substring(with: result.rangeAt(1)))",
                        NSForegroundColorAttributeName: self.linkTintColor,
                        NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
                    ]

                    text.addAttributes(attrs, range: result.rangeAt(1))
                }
            }

            self.textView.attributedText = text
        }
    }

    private func applyCornersRadius() {
        guard let message = self.message else { return }
        let corners: UIRectCorner = message.isOutgoing ? [.bottomLeft, .topLeft, .topRight] : [.bottomRight, .topLeft, .topRight]

        self.container.roundCorners(corners, radius: 16)
        self.container.clipsToBounds = true
    }

    func imageSize(for maxSize: CGSize) -> CGSize {
        guard let message = message, let image = message.image else { return .zero }
        let scale = min(maxSize.width / image.size.width, maxSize.height / image.size.height)

        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    func size(for width: CGFloat) -> CGSize {
        guard let message = self.message else { return .zero }

        let maxWidth: CGFloat = width - self.totalHorizontalMargin
        var totalHeight: CGFloat = 0
        var totalMargin: CGFloat = 0

        if message.image != nil {
            let maxHeight: CGFloat = 200
            totalHeight += imageSize(for: CGSize(width: maxWidth, height: maxHeight)).height
        }

        if let title = message.title, !title.isEmpty {
            totalHeight += title.height(withConstrainedWidth: maxWidth, font: self.titleFont)
            totalMargin += 10
        }

        if let subtitle = message.subtitle, !subtitle.isEmpty {
            totalHeight += subtitle.height(withConstrainedWidth: maxWidth, font: self.subtitleFont)
            totalMargin += 5
        }

        if !message.text.isEmpty {
            totalHeight += message.text.height(withConstrainedWidth: maxWidth, font: self.textFont)
            totalMargin += 10
        }

        if message.buttons.count == 2 {
            let shouldShowButtons = (message.signalMessage.paymentState == .none)

            if message.isActionable && shouldShowButtons {
                totalHeight += message.buttons.first!.title.height(withConstrainedWidth: maxWidth, font: Theme.medium(size: 15)) + 30
                totalHeight += message.buttons.last!.title.height(withConstrainedWidth: maxWidth, font: Theme.medium(size: 15)) + 30
            } else {
                totalHeight += 40
            }
        }

        var extraMargin: CGFloat = message.imageOnly ? 0 : 10

        if message.text.hasEmojiOnly, message.text.characters.count < 4 {
            totalMargin = 0
            extraMargin = -4
        }

        return CGSize(width: ceil(width), height: ceil(totalHeight + totalMargin + extraMargin))
    }
}
