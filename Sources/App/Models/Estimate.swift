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
    
    @Field(key: "internal_reference")
    var internalReference: String
    
    @Field(key: "object")
    var object: String
    
    @Field(key: "total_services")
    var totalServices: Double
    
    @Field(key: "total_materials")
    var totalMaterials: Double
    
    @Field(key: "total_divers")
    var totalDivers: Double
    
    @Field(key: "total")
    var total: Double
    
    @Timestamp(key: "creation", on: .create, format: .default)
    var creation: Date?
    
    @Timestamp(key: "update", on: .update, format: .default)
    var update: Date?
    
    @Enum(key: "status")
    var status: EstimateStatus
    
    @Field(key: "limit_validity_date")
    var limitValidityDate: Date
    
    @Field(key: "sending_date")
    var sendingDate: Date
    
    @Parent(key: "client_id")
    var client: Client
    
    @Siblings(through: ProductEstimate.self, from: \.$estimate, to: \.$product)
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
         totalDivers: Double,
         total: Double,
         status: EstimateStatus,
         limitValidityDate: Date?,
         sendingDate: Date,
         clientID: Client.IDValue,
         isArchive: Bool = false) {
        self.id = id
        self.reference = reference
        self.internalReference = internalReference
        self.object = object
        self.totalServices = totalServices
        self.totalMaterials = totalMaterials
        self.totalDivers = totalDivers
        self.total = total
        self.status = status
        self.limitValidityDate = limitValidityDate ?? Date().addingTimeInterval(2592000)
        self.sendingDate = sendingDate
        self.$client.id = clientID
        self.isArchive = isArchive
    }
}
