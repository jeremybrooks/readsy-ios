//
//  Page.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/7/24.
//

import Foundation

/// Page represents the content that is readable for a given day.
struct Page: Codable, Hashable {
    var heading: String
    var text: String
    
    init() {
        self.heading = "No Content"
        self.text = ""
    }
    
    init(heading: String, text: String) {
        self.heading = heading
        self.text = text
    }
}

