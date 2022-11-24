//
//  UserToken.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class UserToken: Model, Content {
    // Name of the table
    static let schema: String = NameManager.UserToken.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.UserToken.creation.rawValue.fieldKey)
    var creation: Date
    
    @Field(key: NameManager.UserToken.value.rawValue.fieldKey)
    var value: String
    
    @Parent(key: NameManager.UserToken.staffId.rawValue.fieldKey)
    var staff: Staff
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, value: String, staffID: Staff.IDValue) {
        self.id = id
        self.creation = Date()
        self.value = value
        self.$staff.id = staffID
    }
}
