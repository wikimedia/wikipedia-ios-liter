import UIKit

extension UIView {
    func addConstrainedSubview(_ subview: UIView, with insets: NSDirectionalEdgeInsets = .zero, priority: UILayoutPriority = .required) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top)
        topConstraint.priority = priority
        let bottomConstraint = bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: insets.bottom)
        bottomConstraint.priority = priority
        let leftConstraint = subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading)
        leftConstraint.priority = priority
        let rightConstraint = trailingAnchor.constraint(equalTo: subview.trailingAnchor, constant: insets.trailing)
        rightConstraint.priority = priority
        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
    }
}
