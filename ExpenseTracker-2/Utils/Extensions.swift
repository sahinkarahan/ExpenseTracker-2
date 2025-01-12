//
//  Extensions.swift
//  ExpenseTracker-2
//
//  Created by Şahin Karahan on 10.01.2025.
//

import Foundation
import UIKit
import SwiftUI


extension UIColor {
    static func color(data: Data) -> UIColor? {
        do {
            if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                return color
            }
        } catch {
            print("Failed to convert data to UIColor: \(error)")
        }
        return nil
    }
}
