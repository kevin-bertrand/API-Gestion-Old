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
    static let schema: String = NameManager.Estimate.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.Estimate.reference.rawValue.fieldKey)
    var reference: String
    
    @Field(key: NameManager.Estimate.object.rawValue.fieldKey)
    var object: String
    
    @Field(key: NameManager.Estimate.totalServices.rawValue.fieldKey)
    var totalServices: Double
    
    @Field(key: NameManager.Estimate.totalMaterials.rawValue.fieldKey)
    var totalMaterials: Double
    
    @Field(key: NameManager.Estimate.totalDivers.rawValue.fieldKey)
    var totalDivers: Double
    
    @Field(key: NameManager.Estimate.total.rawValue.fieldKey)
    var total: Double
    
    @Timestamp(key: NameManager.Estimate.creation.rawValue.fieldKey, on: .create, format: .default)
    var creation: Date?
    
    @Timestamp(key: NameManager.Estimate.update.rawValue.fieldKey, on: .update, format: .default)
    var update: Date?
    
    @Enum(key: NameManager.Estimate.status.rawValue.fieldKey)
    var status: EstimateStatus
    
    @Field(key: NameManager.Estimate.limitValidityDate.rawValue.fieldKey)
    var limitValidityDate: Date
    
    @Field(key: NameManager.Estimate.sendingDate.rawValue.fieldKey)
    var sendingDate: Date
    
    @Parent(key: NameManager.Estimate.clientId.rawValue.fieldKey)
    var client: Client
    
    @Siblings(through: ProductEstimate.self, from: \.$estimate, to: \.$product)
    public var products: [Product]
    
    @Field(key: NameManager.Estimate.isArchive.rawValue.fieldKey)
    var isArchive: Bool
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         reference: String,
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
