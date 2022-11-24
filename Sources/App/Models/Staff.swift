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
    static let schema: String = NameManager.Staff.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @OptionalField(key: NameManager.Staff.profilePicture.rawValue.fieldKey)
    var profilePicture: String?
    
    @Field(key: NameManager.Staff.firstname.rawValue.fieldKey)
    var firstname: String
    
    @Field(key: NameManager.Staff.lastname.rawValue.fieldKey)
    var lastname: String
    
    @Field(key: NameManager.Staff.phone.rawValue.fieldKey)
    var phone: String
    
    @Field(key: NameManager.Staff.email.rawValue.fieldKey)
    var email: String
    
    @Enum(key: NameManager.Staff.gender.rawValue.fieldKey)
    var gender: Gender
    
    @Enum(key: NameManager.Staff.position.rawValue.fieldKey)
    var position: Position
    
    @Field(key: NameManager.Staff.role.rawValue.fieldKey)
    var role: String
    
    @Field(key: NameManager.Staff.passwordHash.rawValue.fieldKey)
    var passwordHash: String
    
    @Enum(key: NameManager.Staff.permissions.rawValue.fieldKey)
    var permissions: Permissions
    
    @Parent(key: NameManager.Staff.addressId.rawValue.fieldKey)
    var address: Address
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         profilePicture: String? = nil,
         firstname: String,
         lastname: String,
         phone: String,
         email: String,
         gender: Gender = .notDetermined,
         position: Position,
         role: String,
         passwordHash: String,
         permissions: Permissions,
         addressID: Address.IDValue) {
        self.id = id
        self.profilePicture = profilePicture
        self.firstname = firstname
        self.lastname = lastname
        self.phone = phone
        self.email = email
        self.gender = gender
        self.position = position
        self.role = role
        self.passwordHash = passwordHash
        self.permissions = permissions
        self.$address.id = addressID
    }
}
