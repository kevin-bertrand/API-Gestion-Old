//
//  Invoice.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class Invoice: Model, Content {
    // Name of the table
    static let schema: String = "invoice"
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: "reference")
    var reference: String
    
    @Field(key: "internal_reference")
    var internalReference: String
    
    @Field(key: "object")
    var object: String
    
    @Field(key: "total_services")
    var totalServices: Double
    
    @Field(key: "total_materials")
    var totalMaterials: Double
    
    @Field(key: "total")
    var total: Double
    
    @Field(key: "reduction")
    var reduction: Double
    
    @Field(key: "grand_total")
    var grandTotal: Double
    
    @Timestamp(key: "creation", on: .create, format: .default)
    var creation: Date?
    
    @Timestamp(key: "update", on: .update, format: .default)
    var update: Date?
    
    @Enum(key: "status")
    var status: InvoiceStatus
    
    @Field(key: "limit_payment_date")
    var limitPayementDate: Date
    
    @Parent(key: "client_id")
    var client: Client
    
    @Siblings(through: ProductInvoice.self, from: \.$invoice, to: \.$product)
    public var products: [Product]
    
    @Field(key: "is_archive")
    var isArchive: Bool
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         reference: String,
         internalReference: String,
         object: String,
         totalServices: Double,
         totalMaterials: Double,
         total: Double,
         reduction: Double,
         grandTotal: Double,
         status: InvoiceStatus,
         limitPayementDate: Date? = nil,
         clientID: Client.IDValue,
         isArchive: Bool = false) {
        self.id = id
        self.internalReference = internalReference
        self.object = object
        self.reference = reference
        self.totalServices = totalServices
        self.totalMaterials = totalMaterials
        self.total = total
        self.reduction = reduction
        self.grandTotal = grandTotal
        self.status = status
        self.limitPayementDate = limitPayementDate ?? Date().addingTimeInterval(2592000)
        self.$client.id = clientID
        self.isArchive = isArchive
    }
}
