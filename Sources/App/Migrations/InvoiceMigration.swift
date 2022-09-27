//
//  InvoiceMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct InvoiceMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        let invoiceStatus = try await database.enum("invoice_status").read()
        
        try await database.schema(Invoice.schema)
            .id()
            .field("reference", .string, .required)
            .field("internal_reference", .string, .required)
            .field("object", .string, .required)
            .field("total_services", .double, .required)
            .field("total_materials", .double, .required)
            .field("total_divers", .double, .required)
            .field("total", .double, .required)
            .field("grand_total", .double, .required)
            .field("creation", .datetime)
            .field("update", .datetime)
            .field("status", invoiceStatus, .required)
            .field("limit_payment_date", .date, .required)
            .field("facturation_date", .date, .required)
            .field("delay_days", .int32, .required)
            .field("total_delay", .double, .required)
            .field("client_id", .uuid, .required, .references(Client.schema, "id"))
            .field("payment_id", .uuid, .references(PayementMethod.schema, "id"))
            .field("is_archive", .bool, .required)
            .field("comment", .string)
            .unique(on: "reference")
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(Invoice.schema).delete()
    }
}

