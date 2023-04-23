//
//  Address.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class Address: Model, Content {
    // Name of the table
    static let schema: String = NameManager.Address.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.Address.roadName.rawValue.fieldKey)
    var roadName: String
    
    @Field(key: NameManager.Address.streetNumber.rawValue.fieldKey)
    var streetNumber: String
    
    @OptionalField(key: NameManager.Address.complement.rawValue.fieldKey)
    var complement: String?
    
    @Field(key: NameManager.Address.zipCode.rawValue.fieldKey)
    var zipCode: String
    
    @Field(key: NameManager.Address.city.rawValue.fieldKey)
    var city: String
    
    @Field(key: NameManager.Address.country.rawValue.fieldKey)
    var country: String
    
    @Field(key: NameManager.Address.latitude.rawValue.fieldKey)
    var latitude: Double
    
    @Field(key: NameManager.Address.longitude.rawValue.fieldKey)
    var longitude: Double
    
    @OptionalField(key: NameManager.Address.comment.rawValue.fieldKey)
    var comment: String?
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         streetNumber: String,
         roadName: String,
         complement: String? = nil,
         zipCode: String,
         city: String,
         country: String,
         latitude: Double,
         longitude: Double,
         comment: String? = nil) {
        self.id = id
        self.roadName = roadName
        self.streetNumber = streetNumber
        self.complement = complement
        self.zipCode = zipCode
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.comment = comment
    }
}
