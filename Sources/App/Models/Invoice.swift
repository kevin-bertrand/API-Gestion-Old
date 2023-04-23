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
    static let schema: String = NameManager.Invoice.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.Invoice.reference.rawValue.fieldKey)
    var reference: String
    
    @Field(key: NameManager.Invoice.object.rawValue.fieldKey)
    var object: String
    
    @Field(key: NameManager.Invoice.totalServices.rawValue.fieldKey)
    var totalServices: Double
    
    @Field(key: NameManager.Invoice.totalMaterials.rawValue.fieldKey)
    var totalMaterials: Double
    
    @Field(key: NameManager.Invoice.totalDivers.rawValue.fieldKey)
    var totalDivers: Double
    
    @Field(key: NameManager.Invoice.total.rawValue.fieldKey)
    var total: Double
    
    @Field(key: NameManager.Invoice.grandTotal.rawValue.fieldKey)
    var grandTotal: Double
    
    @Timestamp(key: NameManager.Invoice.creation.rawValue.fieldKey, on: .create, format: .default)
    var creation: Date?
    
    @Timestamp(key: NameManager.Invoice.update.rawValue.fieldKey, on: .update, format: .default)
    var update: Date?
    
    @Enum(key: NameManager.Invoice.status.rawValue.fieldKey)
    var status: InvoiceStatus
    
    @Field(key: NameManager.Invoice.limitPaymentDate.rawValue.fieldKey)
    var limitPayementDate: Date
    
    @Field(key: NameManager.Invoice.facturationDate.rawValue.fieldKey)
    var facturationDate: Date
    
    @Field(key: NameManager.Invoice.delayDays.rawValue.fieldKey)
    var delayDays: Int
    
    @Field(key: NameManager.Invoice.totalDelay.rawValue.fieldKey)
    var totalDelay: Double
    
    @Parent(key: NameManager.Invoice.clientId.rawValue.fieldKey)
    var client: Client
    
    @OptionalParent(key: NameManager.Invoice.paymentId.rawValue.fieldKey)
    var payment: PayementMethod?
    
    @Siblings(through: ProductInvoice.self, from: \.$invoice, to: \.$product)
    public var products: [Product]
    
    @Field(key: NameManager.Invoice.isArchive.rawValue.fieldKey)
    var isArchive: Bool
    
    @OptionalField(key: NameManager.Invoice.comment.rawValue.fieldKey)
    var comment: String?
    
    @OptionalField(key: NameManager.Invoice.maxInterests.rawValue.fieldKey)
    var maxInterests: Double?
    
    @OptionalField(key: NameManager.Invoice.limitMaxInterests.rawValue.fieldKey)
    var limitMaxInterests: Date?
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         reference: String,
         object: String,
         totalServices: Double,
         totalMaterials: Double,
         totalDivers: Double,
         total: Double,
         grandTotal: Double,
         status: InvoiceStatus,
         limitPayementDate: Date? = nil,
         delayDays: Int = 0,
         totalDelay: Double = 0.0,
         clientID: Client.IDValue,
         paymentID: PayementMethod.IDValue? = nil,
         facturationDate: Date,
         comment: String?,
         maxInterests: Double?,
         limitMaxInterests: Date?,
         isArchive: Bool = false) {
        self.id = id
        self.object = object
        self.reference = reference
        self.totalServices = totalServices
        self.totalMaterials = totalMaterials
        self.totalDivers = totalDivers
        self.total = total
        self.grandTotal = grandTotal
        self.status = status
        self.limitPayementDate = limitPayementDate ?? Date().addingTimeInterval(2592000)
        self.facturationDate = facturationDate
        self.delayDays = delayDays
        self.totalDelay = totalDelay
        self.$client.id = clientID
        self.$payment.id = paymentID
        self.isArchive = isArchive
        self.comment = comment
        self.maxInterests = maxInterests
        self.limitMaxInterests = limitMaxInterests
    }
}
