//
//  File.swift
//  
//
//  Created by Kevin Bertrand on 20/09/2022.
//

import Foundation
import Fluent
import Queues
import Vapor

struct InvoiceStatusJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        print("ok")
        try await checkInvoiceStatus(on: context.application.db)
    }
    
    private func checkInvoiceStatus(on db: Database) async throws {
        let invoices = try await Invoice.query(on: db)
            .filter(\.$status == .sent)
            .all()
        
        for invoice in invoices {
            if invoice.limitPayementDate > Date() {
                try await Invoice.query(on: db)
                    .set(\.$status, to: .overdue)
                    .filter(\.$reference == invoice.reference)
                    .update()
            }
        }
    }
}
