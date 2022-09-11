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
        try await database.schema(MonthRevenue.schema)
            .id()
            .field("month", .int32, .required)
            .field("year", .int32, .required)
            .field("total_services", .double, .required)
            .field("total_materials", .double, .required)
            .field("total_divers", .double, .required)
            .field("grand_total", .double, .required)
            .unique(on: "month", "year")
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(MonthRevenue.schema).delete()
    }
}

