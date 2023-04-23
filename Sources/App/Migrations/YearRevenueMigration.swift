//
//  YearRevenueMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct YearRevenueMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(NameManager.YearRevenue.schema.rawValue)
            .id()
            .field(NameManager.YearRevenue.year.rawValue.fieldKey, .int32, .required)
            .field(NameManager.YearRevenue.totalServices.rawValue.fieldKey, .double, .required)
            .field(NameManager.YearRevenue.totalMaterials.rawValue.fieldKey, .double, .required)
            .field(NameManager.YearRevenue.totalDivers.rawValue.fieldKey, .double, .required)
            .field(NameManager.YearRevenue.grandTotal.rawValue.fieldKey, .double, .required)
            .unique(on: NameManager.YearRevenue.year.rawValue.fieldKey)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.YearRevenue.schema.rawValue).delete()
    }
}

