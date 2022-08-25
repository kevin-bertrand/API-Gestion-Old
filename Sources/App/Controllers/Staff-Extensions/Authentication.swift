//
//  Authentication.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

extension Staff: ModelAuthenticatable {
    static var usernameKey = \Staff.$email
    static var passwordHashKey = \Staff.$passwordHash
    
    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.passwordHash)
    }
    
    func generateToken() throws -> UserToken {
        return try UserToken(value: [UInt8].random(count: 16).base64, staffID: self.requireID())
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$staff
    
    var isValid: Bool {
        if self.creation.timeIntervalSinceNow >= 2592000 {
            return false
        } else {
            return true
        }
    }
}
