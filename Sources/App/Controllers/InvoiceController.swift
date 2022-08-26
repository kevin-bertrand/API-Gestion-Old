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
    /// Update invoice
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