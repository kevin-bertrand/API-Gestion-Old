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
        let invoiceStatus = try await database.enum(NameManager.Enumeration.invoiceStatus.rawValue).read()
        
        try await database.schema(NameManager.Invoice.schema.rawValue)
            .id()
            .field(NameManager.Invoice.reference.rawValue.fieldKey, .string, .required)
            .field(NameManager.Invoice.object.rawValue.fieldKey, .string, .required)
            .field(NameManager.Invoice.totalServices.rawValue.fieldKey, .double, .required)
            .field(NameManager.Invoice.totalMaterials.rawValue.fieldKey, .double, .required)
            .field(NameManager.Invoice.totalDivers.rawValue.fieldKey, .double, .required)
            .field(NameManager.Invoice.total.rawValue.fieldKey, .double, .required)
            .field(NameManager.Invoice.grandTotal.rawValue.fieldKey, .double, .required)
            .field(NameManager.Invoice.creation.rawValue.fieldKey, .datetime)
            .field(NameManager.Invoice.update.rawValue.fieldKey, .datetime)
            .field(NameManager.Invoice.status.rawValue.fieldKey, invoiceStatus, .required)
            .field(NameManager.Invoice.limitPaymentDate.rawValue.fieldKey, .date, .required)
            .field(NameManager.Invoice.facturationDate.rawValue.fieldKey, .date, .required)
            .field(NameManager.Invoice.delayDays.rawValue.fieldKey, .int32, .required)
            .field(NameManager.Invoice.totalDelay.rawValue.fieldKey, .double, .required)
            .field(NameManager.Invoice.clientId.rawValue.fieldKey, .uuid, .required, .references(Client.schema, "id"))
            .field(NameManager.Invoice.paymentId.rawValue.fieldKey, .uuid, .references(PayementMethod.schema, "id"))
            .field(NameManager.Invoice.isArchive.rawValue.fieldKey, .bool, .required)
            .field(NameManager.Invoice.maxInterests.rawValue.fieldKey, .double)
            .field(NameManager.Invoice.limitMaxInterests.rawValue.fieldKey, .date)
            .field(NameManager.Invoice.comment.rawValue.fieldKey, .string)
            .unique(on: NameManager.Invoice.reference.rawValue.fieldKey)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.Invoice.schema.rawValue).delete()
    }
}

