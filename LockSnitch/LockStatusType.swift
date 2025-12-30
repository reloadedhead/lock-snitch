//
//  LockStatusType.swift
//  homebridge-mac-snitch
//
//  Created by Tomás García Gobet on 30.12.25.
//

import Foundation

enum LockStatusType: String, CaseIterable, Codable {
    case boolean = "Boolean"
    case number = "Number"
    
    func value(for isLocked: Bool) -> String {
        switch self {
        case .boolean:
            return isLocked ? "true" : "false"
        case .number:
            return isLocked ? "1" : "0"
        }
    }
}
