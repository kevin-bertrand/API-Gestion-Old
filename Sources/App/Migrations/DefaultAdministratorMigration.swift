//
//  DefaultAdministratorMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct DefaultAdministratorMigration: AsyncMigration {
    // MARK: Properties
    let environment: Environment
    
    // MARK: Initialization
    init(environment: Environment) {
        self.environment = environment
    }
    
    // MARK: Methods
    // Create DB
    func prepare(on database: Database) async throws {
        let password = {
            if environment == .testing {
                return Environment.get("ADMINISTRATOR_DEV_PASSWORD")
            } else {
                return Environment.get("ADMINISTRATOR_PASSWORD")
            }
        }()
        
        let firstname = Environment.get("ADMINISTRATOR_FIRSTNAME")
        let lastname = Environment.get("ADMINISTRATOR_LASTNAME")
        let phone = Environment.get("ADMINISTRATOR_PHONE")
        let email = Environment.get("ADMINISTRATOR_EMAIL")
        let role = Environment.get("ADMINISTRATOR_ROLE")
        
        let streetNumber = Environment.get("ADMINISTRATOR_ADDRESS_NUMBER")
        let roadName = Environment.get("ADMINISTRATOR_ADDRESS_NAME")
        let zipCode = Environment.get("ADMINISTRATOR_ADDRESS_ZIPCODE")
        let city = Environment.get("ADMINISTRATOR_ADDRESS_CITY")
        let country = Environment.get("ADMINISTRATOR_ADDRESS_COUNTRY")
        let latitude = Environment.get("ADMINISTRATOR_ADDRESS_LATITUDE")
        let longitude = Environment.get("ADMINISTRATOR_ADDRESS_LONGITUDE")

        guard let firstname = firstname,
              let lastname = lastname,
              let phone = phone,
              let email = email,
              let role = role,
              let password = password,
              let streetNumber = streetNumber,
              let roadName = roadName,
              let zipCode = zipCode,
              let city = city,
              let country = country,
              let latitude = latitude,
              let latitudeInDouble = Double(latitude),
              let longitude = longitude,
              let longitudeInDouble = Double(longitude) else {
            throw Abort(.custom(code: 404, reasonPhrase: "Environment values not found"))
        }
        
        guard let addressUUID = UUID(uuidString: "6c78a87c-2492-11ed-861d-0242ac120002") else {
            throw Abort(.internalServerError)
        }
        
        let emptyAddress = Address(id:addressUUID,
                                   streetNumber: streetNumber,
                                   roadName: roadName,
                                   complement: Environment.get("ADMINISTRATOR_ADDRESS_COMPLEMENT"),
                                   zipCode: zipCode,
                                   city: city,
                                   country: country,
                                   latitude: latitudeInDouble,
                                   longitude: longitudeInDouble)
        try await emptyAddress.save(on: database)
        
        let administratorUser = Staff(firstname: firstname,
                                      lastname: lastname,
                                      phone: phone,
                                      email: email,
                                      position: .leadingBoard,
                                      role: role,
                                      passwordHash: try Bcrypt.hash(password),
                                      permissions: .admin,
                                      addressID: addressUUID)
        try await administratorUser.save(on: database)
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {}
}

