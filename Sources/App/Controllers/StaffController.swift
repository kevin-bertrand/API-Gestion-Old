//
//  StaffController.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct StaffController: RouteCollection {
    // MARK: Properties
    var addressController: AddressController
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let staffGroup = routes.grouped("staff")
        
        let basicGroup = staffGroup.grouped(Staff.authenticator()).grouped(Staff.guardMiddleware())
        basicGroup.post("login", use: login)
        
        let tokenGroup = staffGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.post("add", use: create)
        tokenGroup.delete(":id", use: delete)
    }
    
    // MARK: Routes functions
    /// Login function
    private func login(req: Request) async throws -> Response {
        let userAuth = try getUserAuthFor(req)
        
        let token = try await generateToken(for: userAuth, in: req)
        
        let staffInformations = Staff.Login(firstname: userAuth.firstname,
                                            lastname: userAuth.lastname,
                                            phone: userAuth.phone,
                                            email: userAuth.email,
                                            gender: userAuth.gender,
                                            position: userAuth.position,
                                            role: userAuth.role,
                                            token: token.value,
                                            permissions: userAuth.permissions,
                                            address: try await addressController.getAddressFromId(userAuth.$address.id, for: req))
        
        return formatResponse(status: .ok, body: try encodeBody(staffInformations))
    }
    
    /// Create user
    private func create(req: Request) async throws -> Response {
        let userAuth = try getUserAuthFor(req)
        let receivedData = try req.content.decode(Staff.Create.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        let addressID = try await addressController.create(receivedData.address, for: req)
        
        try await Staff(firstname: receivedData.firstname,
                        lastname: receivedData.lastname,
                        phone: receivedData.phone,
                        email: receivedData.email,
                        gender: receivedData.gender,
                        position: receivedData.position,
                        role: receivedData.role,
                        passwordHash: try Bcrypt.hash(try verifyPassword(password: receivedData.password, passwordVerification: receivedData.passwordVerification)),
                        permissions: receivedData.permissions,
                        addressID: try addressID.requireID())
            .save(on: req.db)
        
        return formatResponse(status: .created, body: .empty)
    }
    
    /// Delete user
    private func delete(req: Request) async throws -> Response {
        let userAuth = try getUserAuthFor(req)
        let idToDelete = req.parameters.get("id")
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        guard let idToDelete = idToDelete,
              let id = UUID(uuidString: idToDelete),
              userAuth.id != id,
              let staffToDelete = try await Staff.find(id, on: req.db) else {
            throw Abort(.notAcceptable)
        }
        
        try await staffToDelete.delete(on: req.db)
        
        return formatResponse(status: .ok, body: .empty)
    }
    
    // MARK: Utilities functions
    /// Getting the connected user
    private func getUserAuthFor(_ req: Request) throws -> Staff {
        return try req.auth.require(Staff.self)
    }
    
    /// Generate token when login is success
    private func generateToken(for user: Staff, in req: Request) async throws -> UserToken {
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
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
    
    /// Verify password
    private func verifyPassword(password: String, passwordVerification: String) throws -> String {
        guard password == passwordVerification else {
            throw Abort(.notAcceptable)
        }
        return password
    }
}
