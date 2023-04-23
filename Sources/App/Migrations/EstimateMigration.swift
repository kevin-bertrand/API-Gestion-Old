//
//  EstimateMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct EstimateMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        let estimateStatus = try await database.enum(NameManager.Enumeration.estimateStatus.rawValue).read()
        
        try await database.schema(NameManager.Estimate.schema.rawValue)
            .id()
            .field(NameManager.Estimate.reference.rawValue.fieldKey, .string, .required)
            .field(NameManager.Estimate.object.rawValue.fieldKey, .string, .required)
            .field(NameManager.Estimate.totalServices.rawValue.fieldKey, .double, .required)
            .field(NameManager.Estimate.totalMaterials.rawValue.fieldKey, .double, .required)
            .field(NameManager.Estimate.totalDivers.rawValue.fieldKey, .double, .required)
            .field(NameManager.Estimate.total.rawValue.fieldKey, .double, .required)
            .field(NameManager.Estimate.creation.rawValue.fieldKey, .datetime)
            .field(NameManager.Estimate.update.rawValue.fieldKey, .datetime)
            .field(NameManager.Estimate.status.rawValue.fieldKey, estimateStatus, .required)
            .field(NameManager.Estimate.limitValidityDate.rawValue.fieldKey, .date, .required)
            .field(NameManager.Estimate.clientId.rawValue.fieldKey, .uuid, .required, .references(Client.schema, "id"))
            .field(NameManager.Estimate.sendingDate.rawValue.fieldKey, .date, .required)
            .field(NameManager.Estimate.isArchive.rawValue.fieldKey, .bool, .required)
            .unique(on: NameManager.Estimate.reference.rawValue.fieldKey)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.Estimate.schema.rawValue).delete()
    }
}

