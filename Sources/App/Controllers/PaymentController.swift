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
        tokenGroup.post(use: create)
        tokenGroup.patch(use: update)
        tokenGroup.delete(":id", use: delete)
        tokenGroup.get(use: getList)
        tokenGroup.get(":id", use: getOne)
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
    private func update(req: Request) async throws -> Response {
        let userAuth = try getUserAuthFor(req)
        let updateMethod = try req.content.decode(PayementMethod.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        guard let paymentID = updateMethod.id else {
            throw Abort(.notAcceptable)
        }
        
        try await PayementMethod.query(on: req.db)
            .set(\.$title, to: updateMethod.title)
            .set(\.$iban, to: updateMethod.iban)
            .set(\.$bic, to: updateMethod.bic)
            .filter(\.$id == paymentID)
            .update()
        
        return formatResponse(status: .ok, body: .empty)
    }
    
    /// Delete
    private func delete(req: Request) async throws -> Response {
        let userAuth = try getUserAuthFor(req)
        let paymentID = req.parameters.get("id", as: UUID.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        guard let paymentID = paymentID else {
            throw Abort(.notAcceptable)
        }
        
        try await PayementMethod.find(paymentID, on: req.db)?.delete(on: req.db)
        
        return formatResponse(status: .ok, body: .empty)
    }
    
    /// Get list
    private func getList(req: Request) async throws -> Response {
        let payments = try await PayementMethod.query(on: req.db)
            .all()
        
        return formatResponse(status: .ok, body: try encodeBody(payments))
    }
    
    /// Get one payment method
    private func getOne(req: Request) async throws -> Response {
        let paymentID = req.parameters.get("id", as: UUID.self)
        
        guard let payment = try await PayementMethod.find(paymentID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return formatResponse(status: .ok, body: try encodeBody(payment))
    }
    
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
    private func encodeBody(_ body: any Encodable) throws -> Response.Body {
        return .init(data: try JSONEncoder().encode(body))
    }
}
