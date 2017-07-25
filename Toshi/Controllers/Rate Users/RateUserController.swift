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
import SweetUIKit
import HPGrowingTextView

protocol RateUserControllerDelegate: class {
    func didRate(_ user: TokenUser, rating: Int, review: String)
}

class RateUserController: ModalPresentable {

    static let contentWidth: CGFloat = 270
    static let defaultInputHeight: CGFloat = 35

    weak var delegate: RateUserControllerDelegate?

    fileprivate var user: TokenUser

    fileprivate var review: String = ""

    lazy var reviewContainer: UIView = {
        let view = UIView(withAutoLayout: true)

        return view
    }()

    lazy var titleLabel: TitleLabel = {
        let view = TitleLabel("Rate \(self.user.username)")

        return view
    }()

    lazy var textLabel: UILabel = {
        let view = TextLabel(String(format: NSLocalizedString("How would you rate %@", comment: ""), self.user.displayUsername))
        view.textAlignment = .center
        view.textColor = Theme.darkTextColor

        return view
    }()

    lazy var ratingView: RatingView = {
        let view = RatingView(numberOfStars: 5, customStarSize: 30)
        view.set(rating: 0)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var cancelButton: ActionButton = {
        let view = ActionButton(margin: 0)
        view.title = "Not now"
        view.style = .plain
        view.background.layer.cornerRadius = 0
        view.titleLabel.font = Theme.regular(size: 18)
        view.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var submitButton: ActionButton = {
        let view = ActionButton(margin: 0)
        view.title = "Submit"
        view.style = .plain
        view.background.layer.cornerRadius = 0
        view.titleLabel.font = Theme.semibold(size: 18)
        view.addTarget(self, action: #selector(submit(_:)), for: .touchUpInside)
        view.isEnabled = false

        return view
    }()

    private lazy var dividers: [UIView] = {
        [UIView(withAutoLayout: true), UIView(withAutoLayout: true)]
    }()

    lazy var inputField: HPGrowingTextView = {
        let view = HPGrowingTextView(withAutoLayout: true)
        view.backgroundColor = .white
        view.clipsToBounds = true
        view.layer.cornerRadius = 4
        view.layer.borderColor = Theme.greyTextColor.cgColor
        view.layer.borderWidth = Theme.borderHeight
        view.delegate = self
        view.font = UIFont.systemFont(ofSize: 16)
        view.internalTextView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 5, right: 5)
        view.internalTextView.scrollIndicatorInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 5)
        view.placeholder = " Review (optional)"
        view.returnKeyType = .done

        return view
    }()

    lazy var tapGesture: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        gestureRecognizer.cancelsTouchesInView = false

        return gestureRecognizer
    }()

    lazy var pressGesture: UILongPressGestureRecognizer = {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(press(_:)))
        gestureRecognizer.minimumPressDuration = 0
        gestureRecognizer.cancelsTouchesInView = false

        return gestureRecognizer
    }()

    func tap(_: UITapGestureRecognizer) {

        if inputField.internalTextView.isFirstResponder {
            inputField.internalTextView.resignFirstResponder()
        } else {
            dismiss(animated: true)
        }
    }

    func press(_ gestureRecognizer: UITapGestureRecognizer) {

        let locationInView = gestureRecognizer.location(in: gestureRecognizer.view)
        let margin = (RateUserController.contentWidth - ratingView.frame.width) / 2

        if locationInView.x < margin {
            rating = 0
        } else if locationInView.x > RateUserController.contentWidth - margin {
            rating = ratingView.numberOfStars
        } else {
            let oneStarWidth = ratingView.frame.width / CGFloat(ratingView.numberOfStars)
            self.rating = Int(round((locationInView.x - margin) / oneStarWidth))
        }
    }

    var rating: Int = 0 {
        didSet {
            if self.rating != oldValue {
                self.ratingView.set(rating: max(1, Float(self.rating)), animated: true)
                self.submitButton.isEnabled = true
                self.feedbackGenerator.impactOccurred()
            }
        }
    }

    fileprivate lazy var inputFieldHeight: NSLayoutConstraint = {
        self.inputField.heightAnchor.constraint(equalToConstant: RateUserController.defaultInputHeight)
    }()

    fileprivate lazy var contentViewVerticalCenter: NSLayoutConstraint = {
        self.contentView.centerYAnchor.constraint(equalTo: self.background.centerYAnchor)
    }()

    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        UIImpactFeedbackGenerator(style: .medium)
    }()

    var keyboardHeight: CGFloat = 0 {
        didSet {
            self.contentViewVerticalCenter.constant = self.keyboardHeight > 0 ? -(self.keyboardHeight / 2) + 32 : 0
            self.view.layoutIfNeeded()
        }
    }

    var inputHeight: CGFloat = 0 {
        didSet {
            self.inputFieldHeight.constant = self.inputHeight

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOutFromCurrentStateWithUserInteraction, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    init(user: TokenUser) {
        self.user = user

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        transitioningDelegate = self

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    func cancel(_: ActionButton) {
        inputField.internalTextView.resignFirstResponder()
        dismiss(animated: true)
    }

    func submit(_: ActionButton) {
        delegate?.didRate(user, rating: Int(rating), review: review)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(background)
        view.addSubview(contentView)

        contentView.addSubview(reviewContainer)
        reviewContainer.addSubview(titleLabel)
        reviewContainer.addSubview(textLabel)
        reviewContainer.addSubview(ratingView)

        contentView.addSubview(inputField)
        contentView.addSubview(dividers[0])
        contentView.addSubview(cancelButton)
        contentView.addSubview(dividers[1])
        contentView.addSubview(submitButton)

        contentView.backgroundColor = Theme.viewBackgroundColor.withAlphaComponent(0.7)

        dividers[0].backgroundColor = Theme.greyTextColor
        dividers[1].backgroundColor = Theme.greyTextColor

        NSLayoutConstraint.activate([
            self.background.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.background.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.background.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.background.rightAnchor.constraint(equalTo: self.view.rightAnchor),

            self.contentView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.contentView.widthAnchor.constraint(equalToConstant: RateUserController.contentWidth),
            self.contentViewVerticalCenter,

            self.reviewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.reviewContainer.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.reviewContainer.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),

            self.titleLabel.topAnchor.constraint(equalTo: self.reviewContainer.topAnchor, constant: 20),
            self.titleLabel.leftAnchor.constraint(equalTo: self.reviewContainer.leftAnchor, constant: 40),
            self.titleLabel.rightAnchor.constraint(equalTo: self.reviewContainer.rightAnchor, constant: -40),

            self.textLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 10),
            self.textLabel.leftAnchor.constraint(equalTo: self.reviewContainer.leftAnchor, constant: 40),
            self.textLabel.rightAnchor.constraint(equalTo: self.reviewContainer.rightAnchor, constant: -40),

            self.ratingView.topAnchor.constraint(equalTo: self.textLabel.bottomAnchor, constant: 10),
            self.ratingView.centerXAnchor.constraint(equalTo: self.reviewContainer.centerXAnchor),
            self.ratingView.bottomAnchor.constraint(equalTo: self.reviewContainer.bottomAnchor, constant: -10),

            self.inputField.topAnchor.constraint(equalTo: self.reviewContainer.bottomAnchor, constant: 10),
            self.inputField.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
            self.inputField.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
            self.inputFieldHeight,

            self.dividers[0].topAnchor.constraint(equalTo: self.inputField.bottomAnchor, constant: 20),
            self.dividers[0].leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.dividers[0].rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.dividers[0].heightAnchor.constraint(equalToConstant: Theme.borderHeight),

            self.cancelButton.topAnchor.constraint(equalTo: self.dividers[0].bottomAnchor),
            self.cancelButton.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.cancelButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),

            self.dividers[1].topAnchor.constraint(equalTo: self.cancelButton.bottomAnchor),
            self.dividers[1].leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.dividers[1].rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.dividers[1].heightAnchor.constraint(equalToConstant: Theme.borderHeight),

            self.submitButton.topAnchor.constraint(equalTo: self.dividers[1].bottomAnchor),
            self.submitButton.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.submitButton.rightAnchor.constraint(equalTo: self.contentView.rightAnchor),
            self.submitButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])

        background.addGestureRecognizer(tapGesture)
        reviewContainer.addGestureRecognizer(pressGesture)
    }

    fileprivate dynamic func keyboardWillShow(_ notification: Notification) {
        let info = KeyboardInfo(notification.userInfo)
        keyboardHeight = info.endFrame.height
    }

    fileprivate dynamic func keyboardWillHide(_: Notification) {
        keyboardHeight = 0
    }
}

extension RateUserController: HPGrowingTextViewDelegate {

    func growingTextView(_ textView: HPGrowingTextView!, willChangeHeight _: Float) {
        inputHeight = textView.frame.height
    }

    func growingTextViewDidChange(_ textView: HPGrowingTextView!) {
        inputHeight = textView.frame.height
        review = textView.text
    }

    func growingTextViewShouldReturn(_ growingTextView: HPGrowingTextView!) -> Bool {
        growingTextView.resignFirstResponder()

        return false
    }
}
