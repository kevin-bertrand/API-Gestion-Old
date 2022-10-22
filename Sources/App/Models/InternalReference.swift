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
    static let schema: String = "internal_reference"
    
    // Unique identifier
    @ID()
    var id: UUID?
    
    // Fields
    @Field(key: "ref")
    var ref: String
    
    @OptionalParent(key: "estimate_id")
    var estimate: Estimate?
    
    @OptionalParent(key: "invoice_id")
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
