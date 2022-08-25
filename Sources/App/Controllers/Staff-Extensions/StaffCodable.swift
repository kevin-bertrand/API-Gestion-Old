//
//  StaffCodable.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Foundation

extension Staff {
    struct Login: Codable {
        let firstname: String
        let lastname: String
        let phone: String
        let email: String
        let gender: Gender
        let position: Position
        let role: String
        let token: String
        let address: Address
    }
}
