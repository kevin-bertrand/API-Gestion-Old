//
//  Staff.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class Staff: Model, Content {
    // Name of the table
    static let schema: String = "staff"
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: "firstname")
    var firstname: String
    
    @Field(key: "lastname")
    var lastname: String
    
    @Field(key: "phone")
    var phone: String
    
    @Field(key: "email")
    var email: String
    
    @Enum(key: "gender")
    var gender: Gender
    
    @Enum(key: "position")
    var position: Position
    
    @Field(key: "role")
    var role: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Parent(key: "address_id")
    var address: Address
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         firstname: String,
         lastname: String,
         phone: String,
         email: String,
         gender: Gender = .notDetermined,
         position: Position,
         role: String,
         passwordHash: String,
         addressID: Address.IDValue) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.phone = phone
        self.email = email
        self.gender = gender
        self.position = position
        self.role = role
        self.passwordHash = passwordHash
        self.$address.id = addressID
    }
}
