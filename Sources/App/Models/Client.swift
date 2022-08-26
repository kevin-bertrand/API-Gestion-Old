//
//  Client.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class Client: Model, Content {
    // Name of the table
    static let schema: String = "client"
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @OptionalField(key: "firstname")
    var firstname: String?
    
    @OptionalField(key: "lastname")
    var lastname: String?
    
    @OptionalField(key: "company")
    var company: String?
    
    @Field(key: "phone")
    var phone: String
    
    @Field(key: "email")
    var email: String
    
    @Enum(key: "person_type")
    var personType: PersonType
    
    @Enum(key: "gender")
    var gender: Gender
    
    @OptionalField(key: "siret")
    var siret: String?
    
    @OptionalField(key: "tva")
    var tva: String?
    
    @Parent(key: "address_id")
    var address: Address
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         firstname: String? = nil,
         lastname: String? = nil,
         company: String? = nil,
         phone: String,
         email: String,
         personType: PersonType,
         gender: Gender? = .notDetermined,
         siret: String? = nil,
         tva: String? = nil,
         addressID: Address.IDValue) {
        self.id = id
        self.firstname = firstname
        self.lastname = lastname
        self.company = company
        self.phone = phone
        self.email = email
        self.personType = personType
        self.gender = (personType == .company ? .notDetermined : gender) ?? .notDetermined
        self.siret = siret
        self.tva = tva
        self.$address.id = addressID
    }
}
