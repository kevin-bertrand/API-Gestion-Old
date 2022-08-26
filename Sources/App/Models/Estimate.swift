//
//  Estimate.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class Estimate: Model, Content {
    // Name of the table
    static let schema: String = "estimate"
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: "reference")
    var reference: String
    
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
    
    @Timestamp(key: "creation", on: .create, format: .iso8601)
    var creation: Date?
    
    @Timestamp(key: "update", on: .update, format: .iso8601)
    var update: Date?
    
    @Enum(key: "status")
    var status: EstimateStatus
    
    @Field(key: "limit_validity_date")
    var limitValidityDate: Date
    
    @Parent(key: "client_id")
    var client: Client
    
    @Siblings(through: ProductEstimate.self, from: \.$estimate, to: \.$product)
    public var products: [Product]
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         reference: String,
         totalServices: Double,
         totalMaterials: Double,
         total: Double,
         reduction: Double,
         grandTotal: Double,
         status: EstimateStatus,
         limitValidityDate: Date?,
         clientID: Client.IDValue) {
        self.id = id
        self.reference = reference
        self.totalServices = totalServices
        self.totalMaterials = totalMaterials
        self.total = total
        self.reduction = reduction
        self.grandTotal = grandTotal
        self.status = status
        self.limitValidityDate = limitValidityDate ?? Date().addingTimeInterval(2592000)
        self.$client.id = clientID
    }
}
