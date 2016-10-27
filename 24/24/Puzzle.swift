//
//  Puzzle.swift
//  24
//
//  Created by Belinda Zeng on 10/26/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit
import WatchKit

class Puzzle {
    
    var puzzle: [Int:Int]
//    let puzzleString: String?
    
//    func formatPuzzles(puzzle : [Int:Int]) -> String {
//        var puzzleString = ""
//        for (_, puzzleNumber) in puzzle {
//            puzzleString = " " + String(puzzleNumber) + " "
//        }
//        return puzzleString
//    }
    
    init(puzzle: [Int:Int]) {
        self.puzzle = puzzle
//        self.puzzleString = self.formatPuzzles(puzzle: puzzle)
    }
}
