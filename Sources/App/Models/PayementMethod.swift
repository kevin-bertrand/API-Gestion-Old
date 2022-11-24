//
//  PayementMethod.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class PayementMethod: Model, Content {
    // Name of the table
    static let schema: String = NameManager.PaymentMethod.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.PaymentMethod.title.rawValue.fieldKey)
    var title: String
    
    @Field(key: NameManager.PaymentMethod.iban.rawValue.fieldKey)
    var iban: String
    
    @Field(key: NameManager.PaymentMethod.bic.rawValue.fieldKey)
    var bic: String
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, title: String, iban: String, bic: String) {
        self.id = id
        self.title = title
        self.iban = iban
        self.bic = bic
    }
}
