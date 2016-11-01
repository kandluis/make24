//
//  DoubleExtension.swift
//  24
//
//  Created by Luis Perez on 10/31/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import Foundation

extension Double {
    fileprivate typealias Rational = (num: Int, den: Int)
    
    /*!
     * @brief The numberator when interpreted as a reduced fraction.
     */
    var num: Int {
        return rationalApproximationOf(self).num
    }
    /*!
     * @brief The denominator when interpreted as a reduced fraction.
     */
    var den: Int {
        return rationalApproximationOf(self).den
    }
    
    /*!
     * @discussion Custom initializer from fraction strings. Delages to default.
     * @param from A string representation of the desired double.
     * @return The parsed double.
     */
    init?(from text: String) {
        let comps = text.components(separatedBy: "/")
        if comps.count == 2 {
            // A fraction, convert to double ourselves
            let num = Double(comps[0])!
            let den = Double(comps[1])!
            
            self.init(num / den)
        }
        else {
            self.init(text)
        }
    }
    
    /*!
     * @discussion Improved string conversion method for Doubles supporting fractions.
     * @return A string representation of the doubles value
     */
    func toString() -> String {
        if self.den == 1 {
            return String(self.num)
        }
        return String(format:"%d/%d", self.num, self.den)
    }
    
    // LCM for Double using continued fraction approximation for fast convergence.
    // For more about this method, see: https://en.wikipedia.org/wiki/Continued_fraction
    // For code see: http://stackoverflow.com/questions/28349864/algorithm-for-lcm-of-doubles-in-swift/28352004#28352004
    fileprivate func rationalApproximationOf(_ x0: Double, withPrecision eps: Double = 1.0E-6) -> Rational {
        var x: Double = x0
        var a: Double = floor(x)
        var (h1, k1, h, k): (Int, Int, Int, Int) = (1, 0, Int(a), 1)
        
        while x - a > eps * Double(k) * Double(k) {
            x = 1.0/(x - a)
            a = floor(x)
            (h1, k1, h, k) = (h, k, h1 + Int(a) * h, k1 + Int(a) * k)
        }
        return (h, k)
    }
}

