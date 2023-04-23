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
        tokenGroup.get(use: getList)
        tokenGroup.get(":id", use: getStaffInfo)
        tokenGroup.get("picture", ":image", ":extension", use: getProfilePicture)
        tokenGroup.patch(use: update)
        tokenGroup.patch("password", use: updatePassword)
        tokenGroup.patch("picture", use: updateProfilePicture)
    }
    
    // MARK: Routes functions
    /// Login function
    private func login(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        let receivedData = try req.content.decode(Device.Login.self)
        
        let token = try await generateToken(for: userAuth, in: req)
        
        let staffInformations = Staff.Connected(id: try userAuth.requireID(),
                                                profilePicture: userAuth.profilePicture,
                                                firstname: userAuth.firstname,
                                                lastname: userAuth.lastname,
                                                phone: userAuth.phone,
                                                email: userAuth.email,
                                                gender: userAuth.gender,
                                                position: userAuth.position,
                                                role: userAuth.role,
                                                token: token.value,
                                                permissions: userAuth.permissions,
                                                address: try await addressController.getAddressFromId(userAuth.$address.id, for: req))
        
        // Check if the device doesn't exist
        if let token = receivedData.token,
           try await Device.query(on: req.db).filter(\.$staff.$id == userAuth.requireID()).filter(\.$deviceId == token).first() == nil {
            let newDevice = Device(deviceId: token, staffID: try userAuth.requireID())
            try await newDevice.save(on: req.db)
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(staffInformations)))
    }
    
    /// Create user
    private func create(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
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
        
        return GlobalFunctions.shared.formatResponse(status: .created, body: .empty)
    }
    
    /// Delete user
    private func delete(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
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
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Get staff list
    private func getList(req: Request) async throws -> Response {
        let staff = try await Staff.query(on: req.db)
            .all()
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(staff)))
    }
    
    /// Get one staff info
    private func getStaffInfo(req: Request) async throws -> Response {
        let staffId = req.parameters.get("id")
        
        guard let staffId = staffId,
              let id = UUID(uuidString: staffId),
              let staff = try await Staff.find(id, on: req.db) else {
            throw Abort(.notAcceptable)
        }
        
        let staffInformations = Staff.Information(firstname: staff.firstname, lastname: staff.lastname, phone: staff.phone, email: staff.email, gender: staff.gender, position: staff.position, role: staff.role, permissions: staff.permissions, address: try await addressController.getAddressFromId(staff.$address.id, for: req))
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(staffInformations)))
    }
    
    /// Update staff information
    private func update(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        let user = try req.content.decode(Staff.Update.self)
        
        let updatedAddress = try await addressController.create(user.address, for: req)
        
        try await Staff.query(on: req.db)
            .set(\.$gender, to: user.gender)
            .set(\.$firstname, to: user.firstname)
            .set(\.$lastname, to: user.lastname)
            .set(\.$email, to: user.email)
            .set(\.$phone, to: user.phone)
            .set(\.$role, to: user.role)
            .set(\.$position, to: user.position)
            .set(\.$address.$id, to: try updatedAddress.requireID())
            .filter(\.$id == user.id)
            .update()
        
        let token = try await generateToken(for: userAuth, in: req)
        
        let staffInformations = Staff.Connected(id: user.id,
                                                profilePicture: userAuth.profilePicture,
                                                firstname: user.firstname,
                                                lastname: user.lastname,
                                                phone: user.phone,
                                                email: user.email,
                                                gender: user.gender,
                                                position: user.position,
                                                role: user.role,
                                                token: token.value,
                                                permissions: userAuth.permissions,
                                                address: updatedAddress)
                
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(staffInformations)))
    }
    
    /// Update staff password
    private func updatePassword(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        let updatePassword = try req.content.decode(Staff.UpdatePassword.self)
        
        guard let userId = userAuth.id, userId == updatePassword.id else {
            throw Abort(.unauthorized)
        }
        
        guard try userAuth.verify(password: updatePassword.oldPassword) else {
            throw Abort(.custom(code: 460, reasonPhrase: "The old password is not correct!"))
        }
        
        try await Staff.query(on: req.db)
            .set(\.$passwordHash, to: try Bcrypt.hash(try verifyPassword(password: updatePassword.newPassword, passwordVerification: updatePassword.newPasswordVerification)))
            .filter(\.$id == userId)
            .update()
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Update profile picture
    private func updateProfilePicture(req: Request) async throws -> Response {
        let file = try req.content.decode(File.self)
        guard let fileExtension = file.extension else { throw Abort(.badRequest) }
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        
        guard let userId = userAuth.id else { throw Abort(.unauthorized) }
        
        let path = "/var/www/html/Gestion/Public/\(userId).\(fileExtension)"
        try await req.fileio.writeFile(file.data, at: path)
        
        try await Staff.query(on: req.db)
            .filter(\.$id == userId)
            .set(\.$profilePicture, to: "\(userId)/\(fileExtension)")
            .update()
        
        let token = try await generateToken(for: userAuth, in: req)
        
        let udpatedStaff = Staff.Connected(id: userId,
                                           profilePicture: path,
                                           firstname: userAuth.firstname,
                                           lastname: userAuth.lastname,
                                           phone: userAuth.phone,
                                           email: userAuth.email,
                                           gender: userAuth.gender,
                                           position: userAuth.position,
                                           role: userAuth.role,
                                           token: token.value,
                                           permissions: userAuth.permissions,
                                           address: try await addressController.getAddressFromId(userAuth.$address.id, for: req))
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(udpatedStaff)))
    }
    
    /// Getting profile picture
    private func getProfilePicture(req: Request) async throws -> Response {
        guard let image = req.parameters.get("image"),
              let imageExtension = req.parameters.get("extension") else {
            throw Abort(.notAcceptable)
        }
        
        let downloadedImage = try await req.fileio.collectFile(at: "/var/www/html/Gestion/Public/\(image).\(imageExtension)")
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(buffer: downloadedImage))
    }
    
    // MARK: Utilities functions
    /// Generate token when login is success
    private func generateToken(for user: Staff, in req: Request) async throws -> UserToken {
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }
 
    /// Verify password
    private func verifyPassword(password: String, passwordVerification: String) throws -> String {
        guard password == passwordVerification else {
            throw Abort(.notAcceptable)
        }
        return password
    }
}
