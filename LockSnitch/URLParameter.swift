//
//  URLParameter.swift
//  homebridge-mac-snitch
//
//  Created by Tomás García Gobet on 30.12.25.
//

import Foundation

struct URLParameter: Identifiable, Codable, Equatable {
    let id: UUID
    var key: String
    var value: String
    
    init(id: UUID = UUID(), key: String = "", value: String = "") {
        self.id = id
        self.key = key
        self.value = value
    }
}
