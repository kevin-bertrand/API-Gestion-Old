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
        let estimateStatus = try await database.enum("estimate_status").read()
        
        try await database.schema(Estimate.schema)
            .id()
            .field("reference", .string, .required)
            .field("internal_reference", .string, .required)
            .field("object", .string, .required)
            .field("total_services", .double, .required)
            .field("total_materials", .double, .required)
            .field("total", .double, .required)
            .field("reduction", .double, .required)
            .field("grand_total", .double, .required)
            .field("creation", .string)
            .field("update", .string)
            .field("status", estimateStatus, .required)
            .field("limit_validity_date", .data, .required)
            .field("client_id", .uuid, .required, .references(Client.schema, "id"))
            .unique(on: "reference")
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(Estimate.schema).delete()
    }
}

