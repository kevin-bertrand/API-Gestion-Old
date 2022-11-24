//
//  InternalReferenceController.swift
//  
//
//  Created by Kevin Bertrand on 22/10/2022.
//

import Fluent
import Vapor

struct InternalReferenceController: RouteCollection {
    // MARK: Properties
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let internalRefGroup = routes.grouped("internalRef")
                
        let tokenGroup = internalRefGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.get(":domain", use: getting)
    }
    
    // MARK: Routes functions
    /// Getting internal reference
    private func getting(req: Request) async throws -> Response {
        let domain = req.parameters.get("domain")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy"
        let yearString = dateFormatter.string(from: Date())
        
        var ref = ""
        
        switch domain {
        case Domain.electricity.rawValue:
            ref = "EL"
        case Domain.automation.rawValue:
            ref = "AU"
        case Domain.development.rawValue:
            ref = "DEV"
        case Domain.project.rawValue:
            ref = "PRO"
        case Domain.dao.rawValue:
            ref = "DAO"
        default:
            throw Abort(.notAcceptable)
        }
        
        ref.append(yearString)
        
        let references = try await InternalReference.query(on: req.db)
            .filter(\.$ref =~ ref)
            .all()
            .map({ reference in
                return reference.ref.replacingOccurrences(of: ref, with: "")
            })
        
        var referencesInt = [Int]()
        
        for reference in references {
            guard let refInt = Int(reference) else {
                throw Abort(.internalServerError)
            }
            
            referencesInt.append(refInt)
        }
    
        var newReference = ref
        
        if let maxRef = referencesInt.max() {
            let newNumber = "\(maxRef + 1)"
            
            switch newNumber.count {
            case 1:
                newReference.append("00")
            case 2:
                newReference.append("0")
            default:
                break
            }
            
            newReference.append(newNumber)
        } else {
            newReference.append("001")
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(newReference)))
    }
}

