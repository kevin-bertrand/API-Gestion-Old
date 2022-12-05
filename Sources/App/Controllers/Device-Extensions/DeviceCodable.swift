//
//  DeviceCodable.swift
//  
//
//  Created by Kevin Bertrand on 05/12/2022.
//

import Foundation

extension Device {
    struct Login: Codable {
        let token: String
    }
}
