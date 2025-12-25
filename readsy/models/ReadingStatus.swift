//
//  ReadingStatus.swift
//  readsy
//
//  Created by Jeremy Brooks on 12/18/24.
//

import Foundation
import SwiftUI


struct ReadingStatus {
    var segments: [ChartSegment]
    
    var read: Int      // number of days read
    var future: Int    // number of days unread after today
    var missing: Int   // number of days not read, up to the current day
    
    init() {
        segments = [ChartSegment(label: "Unknown", value: 1, color: .orange, percentage: 100.0),]
        read = 0
        future = 0
        missing = 0
    }
    
    init(segments: [ChartSegment], read: Int, future: Int, missing: Int) {
        self.segments = segments
        self.read = read
        self.future = future
        self.missing = missing
    }
    
    func chartColors() -> [Color] {
        var colors = [Color]()
        for data in segments {
            colors.append(data.color)
        }
        return colors
    }
}


struct ChartSegment : Identifiable {
    let id = UUID()
    let label: String
    let value: Int
    let color: Color
    let percentage: Double
}

