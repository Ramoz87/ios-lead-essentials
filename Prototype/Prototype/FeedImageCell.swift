//
//  FeedImageCell.swift
//  Prototype
//
//  Created by Yury Ramazanov on 15.01.2025.
//

import UIKit

final class FeedImageCell: UITableViewCell {

    @IBOutlet private(set) var locationContainer: UIView!
    @IBOutlet private(set) var feedImageContainer: UIView!
    @IBOutlet private(set) var locationLabel: UILabel!
    @IBOutlet private(set) var feedImageView: UIImageView!
    @IBOutlet private(set) var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        startAnimateImageLoading()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        startAnimateImageLoading()
    }
    
    func fadeIn(_ image: UIImage?) {
        feedImageView.image = image
        
        UIView.animate(
            withDuration: 0.3,
            delay: 1.3,
            options: [],
            animations: {
                self.feedImageView.alpha = 1
            }) { completed in
                if completed {
                    self.feedImageContainer.stopShimmering()
                }
            }
    }
    
    private func startAnimateImageLoading() {
        feedImageView.alpha = 0
        feedImageContainer.startShimmering()
    }
}

private extension UIView {
    private var shimmerAnimationKey: String {
        return "shimmer"
    }

    func startShimmering() {
        let white = UIColor.white.cgColor
        let alpha = UIColor.white.withAlphaComponent(0.7).cgColor
        let width = bounds.width
        let height = bounds.height

        let gradient = CAGradientLayer()
        gradient.colors = [alpha, white, alpha]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.4)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.6)
        gradient.locations = [0.4, 0.5, 0.6]
        gradient.frame = CGRect(x: -width, y: 0, width: width*3, height: height)
        layer.mask = gradient

        let animation = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.locations))
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]
        animation.duration = 1
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: shimmerAnimationKey)
    }

    func stopShimmering() {
        layer.mask = nil
    }
}
