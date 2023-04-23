//
//  MonthRevenueMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct MonthRevenueMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(NameManager.MonthRevenue.schema.rawValue)
            .id()
            .field(NameManager.MonthRevenue.month.rawValue.fieldKey, .int32, .required)
            .field(NameManager.MonthRevenue.year.rawValue.fieldKey, .int32, .required)
            .field(NameManager.MonthRevenue.totalServices.rawValue.fieldKey, .double, .required)
            .field(NameManager.MonthRevenue.totalMaterials.rawValue.fieldKey, .double, .required)
            .field(NameManager.MonthRevenue.totalDivers.rawValue.fieldKey, .double, .required)
            .field(NameManager.MonthRevenue.grandTotal.rawValue.fieldKey, .double, .required)
            .unique(on: NameManager.MonthRevenue.month.rawValue.fieldKey, NameManager.MonthRevenue.year.rawValue.fieldKey)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.MonthRevenue.schema.rawValue).delete()
    }
}

