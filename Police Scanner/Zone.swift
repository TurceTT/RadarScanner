//
//  Zone.swift
//  Police Scanner
//
//  Created by Emin Ademi on 8/28/19.
//  Copyright © 2019 triCore. All rights reserved.
//

import Foundation

protocol Identifiable {
    var id: String? { get set }
}

struct Zone: Codable, Identifiable {
    
    var id: String? = nil
    let longitude: Double
    let latitude: Double
    
    init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }
}
