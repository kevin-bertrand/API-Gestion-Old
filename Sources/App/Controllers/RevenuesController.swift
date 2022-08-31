//
//  RevenuesController.swift
//  
//
//  Created by Kevin Bertrand on 29/08/2022.
//

import Fluent
import Vapor

struct RevenuesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let revenuesGroup = routes.grouped("revenues")
        
        let tokenGroup = revenuesGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.get("year", ":year", use: getYearRevenue)
        tokenGroup.get("month", ":month", ":year", use: getMonthRevenue)
    }
    
    // MARK: Routes functions
    /// Get year revenue
    private func getYearRevenue(req: Request) async throws -> Response {
        let year = req.parameters.get("year", as: Int.self)
        
        guard let year = year else {
            throw Abort(.notAcceptable)
        }
        
        if let revenues = try await YearRevenue.query(on: req.db).filter(\.$year == year).first() {
            return formatResponse(status: .ok, body: try encodeBody(revenues))
        } else {
            return formatResponse(status: .ok, body: try encodeBody(YearRevenue(year: year, totalServices: 0, totalMaterials: 0, totalDivers: 0, grandTotal: 0)))
        }
    }
    
    /// Get month revenue
    private func getMonthRevenue(req: Request) async throws -> Response{
        let month = req.parameters.get("month", as: Int.self)
        let year = req.parameters.get("year", as: Int.self)
        
        guard let year = year, let month = month else { throw Abort(.notAcceptable) }
        
        if let revenues = try await MonthRevenue.query(on: req.db).filter(\.$month == month).filter(\.$year == year).first() {
            return formatResponse(status: .ok, body: try encodeBody(revenues))
        } else {
            return formatResponse(status: .ok, body: try encodeBody(MonthRevenue(month: month, year: year, totalServices: 0, totalMaterials: 0, totalDivers: 0, grandTotal: 0)))
        }
    }
    
    // MARK: Utilities functions
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
