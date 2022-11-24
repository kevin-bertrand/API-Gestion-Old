//
//  InternalReference.swift
//  
//
//  Created by Kevin Bertrand on 22/10/2022.
//

import Fluent
import Vapor

final class InternalReference: Model, Content {
    // Name of the table
    static let schema: String = NameManager.InternalReference.schema.rawValue
    
    // Unique identifier
    @ID()
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.InternalReference.reference.rawValue.fieldKey)
    var ref: String
    
    @OptionalParent(key: NameManager.InternalReference.estimateId.rawValue.fieldKey)
    var estimate: Estimate?
    
    @OptionalParent(key: NameManager.InternalReference.invoiceId.rawValue.fieldKey)
    var invoice: Invoice?
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, ref: String, estimateID: Estimate.IDValue? = nil, invoiceID: Invoice.IDValue? = nil) {
        self.id = id
        self.ref = ref
        self.$estimate.id = estimateID
        self.$invoice.id = invoiceID
    }
}
