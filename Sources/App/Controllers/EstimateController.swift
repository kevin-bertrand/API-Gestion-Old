//
//  EstimateController.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Fluent
import Vapor

struct EstimateController: RouteCollection {
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let estimateGroup = routes.grouped("estimate")
                
        let tokenGroup = estimateGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.post("add", use: create)
    }
    
    // MARK: Routes functions
    /// Getting new estimate reference
    
    /// Create
    private func create(req: Request) async throws -> Response {
        let newEstimate = try req.content.decode(Estimate.Create.self)
        
        try await Estimate(reference: newEstimate.reference, totalServices: newEstimate.totalServices, totalMaterials: newEstimate.totalMaterials, total: newEstimate.total, reduction: newEstimate.reduction, grandTotal: newEstimate.grandTotal, status: newEstimate.status, limitValidityDate: newEstimate.limitValidifyDate ?? nil, clientID: newEstimate.clientID).save(on: req.db)
        
        let estimate = try await Estimate.query(on: req.db)
            .filter(\.$reference == newEstimate.reference)
            .first()
        
        guard let estimate = estimate else {
            throw Abort(.internalServerError)
        }
        
        for product in newEstimate.products {
            try await ProductEstimate(quantity: product.quantity, productID: product.productID, estimateID: try estimate.requireID()).save(on: req.db)
        }
        
        return formatResponse(status: .created, body: .empty)
    }
    
    /// Update lines
    /// Update status
    /// Export as invoice
    
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
