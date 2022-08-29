//
//  InvoiceController.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Fluent
import Vapor

struct InvoiceController: RouteCollection {
    // MARK: Properties
    var addressController: AddressController
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let invoiceGroup = routes.grouped("invoice")
        
        let tokenGroup = invoiceGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.get("reference", use: getInvoiceReference)
        tokenGroup.post(use: create)
        tokenGroup.patch(use: update)
    }
    
    // MARK: Routes functions
    /// Getting new invoice reference
    private func getInvoiceReference(req: Request) async throws -> Response {
        let invoices = try await Invoice.query(on: req.db).all()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let date = dateFormatter.string(from: Date())
        
        var number: String = "001"
        
        if invoices.count != 0 {
            let lastReference = invoices[invoices.count-1].reference.split(separator: "-")
            guard lastReference.count == 3 else { throw Abort(.internalServerError) }
            
            if lastReference[1] == date {
                guard let lastNumber = Int(lastReference[2]) else { throw Abort(.internalServerError) }
                let newNumber = "\(lastNumber+1)"
                number = ""
                
                for _ in 0..<(3-newNumber.count) { number.append("0")}
                
                number.append(newNumber)
            }
        }
        
        return formatResponse(status: .ok, body: try encodeBody("F-\(date)-\(number)"))
    }
    
    /// Create invoice
    private func create(req: Request) async throws -> Response {
        let newInvoice = try req.content.decode(Invoice.Create.self)
        try await Invoice(reference: newInvoice.reference,
                          internalReference: newInvoice.internalReference,
                          object: newInvoice.object,
                          totalServices: newInvoice.totalServices,
                          totalMaterials: newInvoice.totalMaterials,
                          total: newInvoice.total,
                          reduction: newInvoice.reduction,
                          grandTotal: newInvoice.grandTotal,
                          status: newInvoice.status,
                          limitPayementDate: newInvoice.limitPayementDate,
                          clientID: newInvoice.clientID)
        .save(on: req.db)
        
        let invoice = try await Invoice.query(on: req.db)
            .filter(\.$reference == newInvoice.reference)
            .first()
        
        guard let invoice = invoice, let invoiceId = invoice.id else {
            throw Abort(.internalServerError)
        }
        
        for product in newInvoice.products {
            try await ProductInvoice(quantity: product.quantity, productID: product.productID, invoiceID: invoiceId).save(on: req.db)
        }
        
        return formatResponse(status: .created, body: try encodeBody("\(invoice.reference) is created!"))
    }
    
    /// Update invoice
    private func update(req: Request) async throws -> Response {
        let updatedInvoice = try req.content.decode(Invoice.Update.self)
        
        try await Invoice.query(on: req.db)
            .set(\.$object, to: updatedInvoice.object)
            .set(\.$totalServices, to: updatedInvoice.totalServices)
            .set(\.$totalMaterials, to: updatedInvoice.totalMaterials)
            .set(\.$total, to: updatedInvoice.total)
            .set(\.$reduction, to: updatedInvoice.reduction)
            .set(\.$grandTotal, to: updatedInvoice.grandTotal)
            .set(\.$status, to: updatedInvoice.status)
            .set(\.$limitPayementDate, to: updatedInvoice.limitPayementDate ?? Date().addingTimeInterval(2592000))
            .filter(\.$reference == updatedInvoice.reference)
            .update()
        
        for product in updatedInvoice.products {
            if product.quantity == 0 {
                try await ProductInvoice.query(on: req.db)
                    .filter(\.$product.$id == product.productID)
                    .filter(\.$invoice.$id == updatedInvoice.id)
                    .delete()
            } else {
                if let _ = try await ProductInvoice.query(on: req.db)
                    .filter(\.$product.$id == product.productID)
                    .filter(\.$invoice.$id == updatedInvoice.id)
                    .first() {
                    try await ProductInvoice.query(on: req.db)
                        .set(\.$quantity, to: product.quantity)
                        .filter(\.$product.$id == product.productID)
                        .filter(\.$invoice.$id == updatedInvoice.id)
                        .update()
                } else {
                    try await ProductInvoice(quantity: product.quantity, productID: product.productID, invoiceID: updatedInvoice.id).save(on: req.db)
                }
            }
        }
        
        return formatResponse(status: .ok, body: .empty)
    }
    /// Getting invoice list
    /// Getting invoice
    
    // MARK: Utilities functions
    /// Getting the connected user
    private func getUserAuthFor(_ req: Request) throws -> Staff {
        return try req.auth.require(Staff.self)
    }
    
    /// Formating response
    private func formatResponse(status: HTTPResponseStatus, body: Response.Body) -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        return .init(status: status, headers: headers, body: body)
    }
    
    /// Encode body
    private func encodeBody(_ body: Codable) throws -> Response.Body {
        return .init(data: try JSONEncoder().encode(body))
    }
}
