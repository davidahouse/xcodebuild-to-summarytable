//
//  File.swift
//  
//
//  Created by David House on 2/23/21.
//

import Foundation

struct SummaryTableBadge: Codable {
    let shield: String
    let alt: String
    let logo: String?
    let style: String?
}

struct SummaryTableItem: Codable {
    let title: String
    let link: String?
    let valueString: String?
    let valueBadges: [SummaryTableBadge]
}
