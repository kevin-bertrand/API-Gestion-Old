//
//  StaffCodable.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Foundation

extension Staff {
    struct Update: Codable {
        let id: UUID
        let firstname: String
        let lastname: String
        let phone: String
        let email: String
        let gender: Gender
        let position: Position
        let role: String
        let address: Address
    }
    
    struct Connected: Codable {
        let id: UUID
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
    
    struct UpdatePassword: Codable {
        let id: UUID
        let oldPassword: String
        let newPassword: String
        let newPasswordVerification: String
    }
}
