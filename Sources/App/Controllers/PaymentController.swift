//
//  PaymentController.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Fluent
import Vapor

struct PaymentController: RouteCollection {
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let paymentGroup = routes.grouped("payment")
                
        let tokenGroup = paymentGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.post("add", use: create)
    }
    
    // MARK: Routes functions
    /// Add payment method
    private func create(req: Request) async throws -> Response {
        let userAuth = try getUserAuthFor(req)
        let newMethod = try req.content.decode(PayementMethod.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        try await newMethod.save(on: req.db)
        
        return formatResponse(status: .created, body: .empty)
    }
    
    /// Update
    
    /// Delete
    
    /// Get list
    
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
