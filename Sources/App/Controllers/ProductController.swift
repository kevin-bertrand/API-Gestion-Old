//
//  ProductController.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Fluent
import Vapor

struct ProductController: RouteCollection {
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let productGroup = routes.grouped("product")
                
        let tokenGroup = productGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.post("add", use: create)
    }
    
    // MARK: Routes functions
    /// Get product categories
    
    /// Get domains
    
    /// Create product
    private func create(req: Request) async throws -> Response {
        let userAuth = try getUserAuthFor(req)
        let newProduct = try req.content.decode(Product.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        try await newProduct.save(on: req.db)
        
        return formatResponse(status: .created, body: .empty)
    }
    
    
    /// Update product
    
    /// Get product list
    
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
