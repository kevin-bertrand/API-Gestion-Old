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
    static let schema: String = NameManager.Client.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @OptionalField(key: NameManager.Client.firstname.rawValue.fieldKey)
    var firstname: String?
    
    @OptionalField(key: NameManager.Client.lastname.rawValue.fieldKey)
    var lastname: String?
    
    @OptionalField(key: NameManager.Client.company.rawValue.fieldKey)
    var company: String?
    
    @Field(key: NameManager.Client.phone.rawValue.fieldKey)
    var phone: String
    
    @Field(key: NameManager.Client.email.rawValue.fieldKey)
    var email: String
    
    @Enum(key: NameManager.Client.personType.rawValue.fieldKey)
    var personType: PersonType
    
    @Enum(key: NameManager.Client.gender.rawValue.fieldKey)
    var gender: Gender
    
    @OptionalField(key: NameManager.Client.siret.rawValue.fieldKey)
    var siret: String?
    
    @OptionalField(key: NameManager.Client.tva.rawValue.fieldKey)
    var tva: String?
    
    @Parent(key: NameManager.Client.addressId.rawValue.fieldKey)
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
