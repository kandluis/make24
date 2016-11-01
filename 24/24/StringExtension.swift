//
//  StringExtension.swift
//  24
//
//  Created by Luis Perez on 10/31/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import Foundation

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
