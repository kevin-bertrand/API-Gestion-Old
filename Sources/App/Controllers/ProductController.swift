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
        tokenGroup.post(use: create)
        tokenGroup.patch(":id", use: update)
        tokenGroup.get(use: getList)
        tokenGroup.get(":params", use: getList)
        tokenGroup.get("categories", use: getCategories)
        tokenGroup.get("domains", use: getDomains)
    }
    
    // MARK: Routes functions
    /// Get product categories
    private func getCategories(req: Request) async throws -> Response {
        let categories = ProductCategory.allCases
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(categories)))
    }
    
    /// Get domains
    private func getDomains(req: Request) async throws -> Response {
        let domains = Domain.allCases
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(domains)))
    }
    
    /// Create product
    private func create(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        let newProduct = try req.content.decode(Product.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        try await newProduct.save(on: req.db)
        
        return GlobalFunctions.shared.formatResponse(status: .created, body: .empty)
    }
        
    /// Update product
    private func update(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        let updatedProduct = try req.content.decode(Product.self)
        let productId = req.parameters.get("id")
        
        guard userAuth.permissions == .admin, let productId = productId, let id = UUID(uuidString: productId) else {
            throw Abort(.unauthorized)
        }
        
        try await Product.query(on: req.db)
            .set(\.$productCategory, to: updatedProduct.productCategory)
            .set(\.$domain, to: updatedProduct.domain)
            .set(\.$title, to: updatedProduct.title)
            .set(\.$unity, to: updatedProduct.unity)
            .set(\.$price, to: updatedProduct.price)
            .filter(\.$id == id)
            .update()
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Get product list
    private func getList(req: Request) async throws -> Response {
        let params = req.parameters.get("params")
    
        let products: [Product]
        
        if let params = params {
            let params = params.split(separator: "&")
            var domainFilter: Domain? = nil
            var categoryFilter: ProductCategory? = nil
            
            for param in params {
                let param = param.split(separator: "=")
                
                if param.count == 2 {
                    switch param[0] {
                    case "domain":
                        if let domain = Domain(rawValue: String(param[1])) {
                            domainFilter = domain
                        } else {
                            throw Abort(.notAcceptable)
                        }
                    case "category":
                        if let category = ProductCategory(rawValue: String(param[1])) {
                            categoryFilter = category
                        } else {
                            throw Abort(.notAcceptable)
                        }
                    default:
                        throw Abort(.notAcceptable)
                    }
                } else {
                    throw Abort(.notAcceptable)
                }
            }
            
            if domainFilter != nil && categoryFilter != nil,
               let domainFilter = domainFilter,
               let categoryFilter = categoryFilter {
                products = try await Product.query(on: req.db)
                    .filter(\.$domain == domainFilter)
                    .filter(\.$productCategory == categoryFilter)
                    .all()
            } else if domainFilter != nil && categoryFilter == nil,
                      let domainFilter = domainFilter {
                products = try await Product.query(on: req.db)
                    .filter(\.$domain == domainFilter)
                    .all()
            } else if domainFilter == nil && categoryFilter != nil,
                      let categoryFilter = categoryFilter {
                products = try await Product.query(on: req.db)
                    .filter(\.$productCategory == categoryFilter)
                    .all()
            } else {
                products = try await getAllProducts(req: req)
            }
        } else {
            products = try await getAllProducts(req: req)
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(products)))
    }
    
    // MARK: Utilities functions
    /// Get all product list
    private func getAllProducts(req: Request) async throws -> [Product] {
        return try await Product.query(on: req.db)
            .all()
    }
}
