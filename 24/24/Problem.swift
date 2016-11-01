//
//  Problem.swift
//  24
//
//  Created by Belinda Zeng on 10/28/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import Foundation

class Problem {
    var id : Int!
    var numbers : [Int]!
    var difficulty: Double!
    
    init(id: Int, values: [Int], difficulty: Double) {
        self.id = id
        self.numbers = values
        self.difficulty = difficulty
    }
    
}
