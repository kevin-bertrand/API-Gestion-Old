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
        try await database.schema(YearRevenue.schema)
            .id()
            .field("year", .int8, .required)
            .field("total_services", .double, .required)
            .field("total_materials", .double, .required)
            .field("total_divers", .double, .required)
            .field("grand_total", .double, .required)
            .unique(on: "year")
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(YearRevenue.schema).delete()
    }
}

