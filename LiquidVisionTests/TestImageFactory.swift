//
//  TestImageFactory.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import UIKit

enum TestImageFactory {
    static func makeSolidColorImage(size: CGSize = CGSize(width: 224, height: 224), color: UIColor = .systemBlue) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: size.width * 0.25,
                                                     y: size.height * 0.25,
                                                     width: size.width * 0.5,
                                                     height: size.height * 0.5))
        }
    }
}
