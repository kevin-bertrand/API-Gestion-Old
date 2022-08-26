//
//  StaffCodable.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Foundation

extension Staff {
    struct Connected: Codable {
        let firstname: String
        let lastname: String
        let phone: String
        let email: String
        let gender: Gender
        let position: Position
        let role: String
        let token: String
        let permissions: Permissions
        let address: Address
    }
    
    struct Create: Codable {
        let firstname: String
        let lastname: String
        let phone: String
        let email: String
        let gender: Gender
        let position: Position
        let role: String
        let password: String
        let passwordVerification: String
        let permissions: Permissions
        let address: Address
    }
    
    struct Information: Codable {
        let firstname: String
        let lastname: String
        let phone: String
        let email: String
        let gender: Gender
        let position: Position
        let role: String
        let permissions: Permissions
        let address: Address
    }
}
