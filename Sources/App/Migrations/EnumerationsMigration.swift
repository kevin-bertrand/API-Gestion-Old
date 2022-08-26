//
//  EnumerationsMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct EnumerationsMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        _ = try await database.enum("domain")
            .case("electricity")
            .case("automation")
            .case("development")
            .create()
        
        _ = try await database.enum("estimate_status")
            .case("inCreation")
            .case("sent")
            .case("refused")
            .case("late")
            .create()
        
        _ = try await database.enum("gender")
            .case("man")
            .case("woman")
            .case("notDetermined")
            .create()
        
        _ = try await database.enum("invoice_status")
            .case("inCreation")
            .case("sent")
            .case("payed")
            .case("overdue")
            .create()
        
        _ = try await database.enum("permissions")
            .case("admin")
            .case("user")
            .create()
        
        _ = try await database.enum("person_type")
            .case("company")
            .case("person")
            .create()
        
        _ = try await database.enum("position")
            .case("employee")
            .case("leadingBoard")
            .create()
        
        _ = try await database.enum("product_category")
            .case("material")
            .case("service")
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.enum("domain").delete()
        try await database.enum("estimate_status").delete()
        try await database.enum("gender").delete()
        try await database.enum("invoice_status").delete()
        try await database.enum("person_type").delete()
        try await database.enum("permissions").delete()
        try await database.enum("position").delete()
        try await database.enum("product_category").delete()
    }
}

