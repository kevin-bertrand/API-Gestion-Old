//
//  AddressController.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct AddressController {
    // MARK: Utilities functions
    // MARK: Public
    /// Check if an address is saved. If not save it.
    func create(_ address: Address, for req: Request) async throws -> Address {
        if let savedAddress = try await checkIfAddressExists(address, for: req) {
            return savedAddress
        }
        
        try await address.save(on: req.db)
        
        if let savedAddress = try await checkIfAddressExists(address, for: req) {
            return savedAddress
        } else {
            throw Abort(.internalServerError)
        }
    }
    
    /// Return an address from its ID
    func getAddressFromId(_ id: UUID?, for req: Request) async throws -> Address {
        guard let address = try await Address.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
    
        return address
    }
    
    // MARK: Private
    /// Check if the address already exists
    private func checkIfAddressExists(_ address: Address, for req: Request) async throws -> Address? {
        return try await Address.query(on: req.db)
            .filter(\.$roadName == address.roadName)
            .filter(\.$streetNumber == address.streetNumber)
            .filter(\.$city == address.city)
            .first()
    }
}
