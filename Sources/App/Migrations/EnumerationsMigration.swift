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
        _ = try await database.enum(NameManager.Enumeration.domain.rawValue)
            .case(Domain.electricity.rawValue)
            .case(Domain.automation.rawValue)
            .case(Domain.development.rawValue)
            .case(Domain.project.rawValue)
            .case(Domain.dao.rawValue)
            .create()
        
        _ = try await database.enum(NameManager.Enumeration.estimateStatus.rawValue)
            .case(EstimateStatus.inCreation.rawValue)
            .case(EstimateStatus.sent.rawValue)
            .case(EstimateStatus.refused.rawValue)
            .case(EstimateStatus.late.rawValue)
            .case(EstimateStatus.accepted.rawValue)
            .create()
        
        _ = try await database.enum(NameManager.Enumeration.gender.rawValue)
            .case(Gender.man.rawValue)
            .case(Gender.woman.rawValue)
            .case(Gender.notDetermined.rawValue)
            .create()
        
        _ = try await database.enum(NameManager.Enumeration.invoiceStatus.rawValue)
            .case(InvoiceStatus.inCreation.rawValue)
            .case(InvoiceStatus.sent.rawValue)
            .case(InvoiceStatus.payed.rawValue)
            .case(InvoiceStatus.overdue.rawValue)
            .create()
        
        _ = try await database.enum(NameManager.Enumeration.permissions.rawValue)
            .case(Permissions.admin.rawValue)
            .case(Permissions.user.rawValue)
            .create()
        
        _ = try await database.enum(NameManager.Enumeration.personType.rawValue)
            .case(PersonType.company.rawValue)
            .case(PersonType.person.rawValue)
            .create()
        
        _ = try await database.enum(NameManager.Enumeration.position.rawValue)
            .case(Position.employee.rawValue)
            .case(Position.leadingBoard.rawValue)
            .create()
        
        _ = try await database.enum(NameManager.Enumeration.productCategory.rawValue)
            .case(ProductCategory.material.rawValue)
            .case(ProductCategory.service.rawValue)
            .case(ProductCategory.divers.rawValue)
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.enum(NameManager.Enumeration.domain.rawValue).delete()
        try await database.enum(NameManager.Enumeration.estimateStatus.rawValue).delete()
        try await database.enum(NameManager.Enumeration.gender.rawValue).delete()
        try await database.enum(NameManager.Enumeration.invoiceStatus.rawValue).delete()
        try await database.enum(NameManager.Enumeration.personType.rawValue).delete()
        try await database.enum(NameManager.Enumeration.permissions.rawValue).delete()
        try await database.enum(NameManager.Enumeration.position.rawValue).delete()
        try await database.enum(NameManager.Enumeration.productCategory.rawValue).delete()
    }
}

