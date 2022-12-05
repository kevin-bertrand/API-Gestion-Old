//
//  Device.swift
//  
//
//  Created by Kevin Bertrand on 05/12/2022.
//

import Fluent
import Vapor

final class Device: Model, Content {
    // Name of the table
    static let schema: String = NameManager.Device.schema.rawValue
    
    // Unique identifier
    @ID()
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.Device.deviceId.rawValue.fieldKey)
    var deviceId: String
    
    @Parent(key: NameManager.Device.staffId.rawValue.fieldKey)
    var staff: Staff
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, deviceId: String, staffID: Staff.IDValue) {
        self.id = id
        self.deviceId = deviceId
        self.$staff.id = staffID
    }
}
