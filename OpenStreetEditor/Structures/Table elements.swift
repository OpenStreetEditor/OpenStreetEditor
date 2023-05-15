//
//  PropertiesTable.swift
//  OSM editor
//
//  Created by Arkadiy on 26.02.2023.
//

import Foundation
import UIKit

//  MARK: SOME UI ELEMENTS

//  View for displaying user data
class UserInfoView: UIView {
    var idIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "number.circle"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var idLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var nickIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "person.crop.circle"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var nickLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var timeIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "clock"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(idIcon)
        addSubview(idLabel)
        addSubview(nickIcon)
        addSubview(nickLabel)
        addSubview(timeIcon)
        addSubview(timeLabel)
        NSLayoutConstraint.activate([
            idIcon.topAnchor.constraint(equalTo: topAnchor),
            idIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            idIcon.widthAnchor.constraint(equalToConstant: 24),
            idIcon.heightAnchor.constraint(equalToConstant: 24),
            idLabel.leftAnchor.constraint(equalTo: idIcon.rightAnchor, constant: 5),
            idLabel.centerYAnchor.constraint(equalTo: idIcon.centerYAnchor),
            idLabel.rightAnchor.constraint(equalTo: rightAnchor),
            nickIcon.topAnchor.constraint(equalTo: idIcon.bottomAnchor, constant: 5),
            nickIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            nickIcon.widthAnchor.constraint(equalToConstant: 24),
            nickIcon.heightAnchor.constraint(equalToConstant: 24),
            nickLabel.leftAnchor.constraint(equalTo: nickIcon.rightAnchor, constant: 5),
            nickLabel.centerYAnchor.constraint(equalTo: nickIcon.centerYAnchor),
            nickLabel.rightAnchor.constraint(equalTo: rightAnchor),
            timeIcon.topAnchor.constraint(equalTo: nickIcon.bottomAnchor, constant: 5),
            timeIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            timeIcon.widthAnchor.constraint(equalToConstant: 24),
            timeIcon.heightAnchor.constraint(equalToConstant: 24),
            timeLabel.leftAnchor.constraint(equalTo: timeIcon.rightAnchor, constant: 5),
            timeLabel.centerYAnchor.constraint(equalTo: timeIcon.centerYAnchor),
            timeLabel.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
}

//  View with the authorization result on the authorization controller
class AuthResultView: UIView {
    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18)
        label.baselineAdjustment = .alignCenters
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
        update()
    }
    
    func setupConstrains() {
        addSubview(icon)
        addSubview(label)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 24),
            icon.widthAnchor.constraint(equalToConstant: 24),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 5),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
    
    //  Method update view after authorization
    func update() {
        var server = ""
        if AppSettings.settings.isDevServer {
            server = "developer server"
        } else {
            server = "production server"
        }
        if AppSettings.settings.token == nil {
            icon.image = UIImage(named: "cancel")
            label.text = "Authorization on \(server) failed"
        } else {
            icon.image = UIImage(named: "success")
            if let login = AppSettings.settings.userName {
                label.text = "You are logged in to the \(server) as \(login)"
            } else {
                label.text = "Authorization on \(server) success"
            }
        }
    }
}

//  View for manual input of a tag=value pair
class AddTagManuallyView: UIView {
    var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let message = """
        Please, pay attention to character case!
        "Highway" is not equal to "highway".
        """
        label.text = message
        label.numberOfLines = 2
        return label
    }()
    
    var keyField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.clearButtonMode = .always
        field.autocapitalizationType = .none
        field.placeholder = "Enter key"
        return field
    }()

    var valueField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.clearButtonMode = .always
        field.autocapitalizationType = .none
        field.placeholder = "Enter value"
        return field
    }()

    lazy var toolbar: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let enterButton = UIButton()
        enterButton.setTitle("Enter", for: .normal)
        enterButton.setTitleColor(.systemBlue, for: .normal)
        enterButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        enterButton.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(cancelButton)
        stack.addArrangedSubview(enterButton)
        stack.distribution = .fillEqually
        stack.backgroundColor = .systemGray5
        return stack
    }()
    
    @objc func doneButtonTapped() {
        guard let clouser = callbackClosure,
              var key = keyField.text,
              let value = valueField.text else { return }
        key = key.lowercased()
        clouser([key: value])
        removeFromSuperview()
    }
    
    @objc func cancelButtonTapped() {
        guard let clouser = callbackClosure else { return }
        clouser([:])
        removeFromSuperview()
    }
    
    var callbackClosure: (([String: String]) -> Void)?
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(keyField)
        addSubview(valueField)
        addSubview(toolbar)
        addSubview(messageLabel)
        NSLayoutConstraint.activate([
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
            toolbar.leftAnchor.constraint(equalTo: leftAnchor),
            toolbar.rightAnchor.constraint(equalTo: rightAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 50),
            keyField.heightAnchor.constraint(equalToConstant: 50),
            keyField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            keyField.rightAnchor.constraint(equalTo: centerXAnchor, constant: -7),
            keyField.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -20),
            valueField.leftAnchor.constraint(equalTo: centerXAnchor, constant: 7),
            valueField.heightAnchor.constraint(equalToConstant: 50),
            valueField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
            valueField.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: keyField.topAnchor, constant: -20),
            messageLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            messageLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
            messageLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}

//  TitleView for the tag editing controller
class EditTitleView: UIView {
    var icon: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18)
        label.baselineAdjustment = .alignCenters
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var listIcon: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "chevron.down"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    convenience init() {
        self.init(frame: .zero)
        setupConstrains()
    }
    
    func setupConstrains() {
        addSubview(icon)
        addSubview(label)
        addSubview(listIcon)
        let iconSize = CGFloat(18)
        let listIconSize = CGFloat(18)
        NSLayoutConstraint.activate([
            icon.leftAnchor.constraint(equalTo: leftAnchor, constant: 7),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: iconSize),
            icon.widthAnchor.constraint(equalToConstant: iconSize),
            listIcon.rightAnchor.constraint(equalTo: rightAnchor, constant: -7),
            listIcon.heightAnchor.constraint(equalToConstant: listIconSize),
            listIcon.widthAnchor.constraint(equalToConstant: listIconSize),
            listIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 5),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.rightAnchor.constraint(equalTo: listIcon.leftAnchor, constant: -7),
        ])
    }
}

//  Custom button for switching to the controller of saved objects
class SavedObjectButton: UIButton {
    private let greenCircle = UIView()

    init() {
        super.init(frame: .zero)
        setupGreenCircle()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGreenCircle() {
        greenCircle.backgroundColor = .systemGreen
        greenCircle.layer.cornerRadius = 4 // Радиус для круглой формы
        greenCircle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(greenCircle)

        NSLayoutConstraint.activate([
            greenCircle.widthAnchor.constraint(equalToConstant: 8),
            greenCircle.heightAnchor.constraint(equalToConstant: 8),
            greenCircle.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            greenCircle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
        ])
        
        greenCircle.isHidden = true // Изначально кружок скрыт
    }

    func showGreenCircle() {
        greenCircle.isHidden = false
    }

    func hideGreenCircle() {
        greenCircle.isHidden = true
    }
}

//  Custom cell for a tag value selection controller that allows multiple values
class SelectValuesCell: UITableViewCell {
    var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var checkBox: CheckBox = {
        let checkBox = CheckBox()
        checkBox.isChecked = false
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        return checkBox
    }()
    
    func setupConstrains() {
        contentView.addSubview(label)
        contentView.addSubview(checkBox)
        NSLayoutConstraint.activate([
            checkBox.rightAnchor.constraint(equalTo: rightAnchor, constant: -30),
            checkBox.widthAnchor.constraint(equalToConstant: 50),
            checkBox.heightAnchor.constraint(equalTo: heightAnchor),
            checkBox.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.rightAnchor.constraint(equalTo: checkBox.leftAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            label.topAnchor.constraint(equalTo: topAnchor),
        ])
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isUserInteractionEnabled = true
        setupConstrains()
    }
        
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        checkBox.isChecked = false
        label.text = nil
    }
}

//  The button that is used to select the tag values from the list. Used on the tag editing controller and ItemVC
class MultiSelectBotton: UIButton {
    var key: String?
    var values: [String] = []
}

//  Custom UITextField for entering the text value of the tag. Use in ItemVC and EditObjectVC
class ValueField: UITextField, UITextFieldDelegate {
    var key: String?
    var indexPath: IndexPath?
}

class CheckBox: UIButton {
    let checkedImage = UIImage(systemName: "square")
    let uncheckedImage = UIImage(systemName: "checkmark.square")
    
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                setImage(uncheckedImage?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), for: .normal)
            } else {
                setImage(checkedImage?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), for: .normal)
            }
        }
    }
    
    var indexPath = IndexPath()
}
