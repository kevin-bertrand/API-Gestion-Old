//
//  WidgetController.swift
//  
//
//  Created by Kevin Bertrand on 05/12/2022.
//

import Fluent
import Vapor

struct WidgetController: RouteCollection {
    // MARK: Properties
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let widgetGroup = routes.grouped("widget")
        let basicGroup = widgetGroup.grouped(Staff.authenticator()).grouped(Staff.guardMiddleware())
        basicGroup.get(use: getInformations)
    }
    
    // MARK: Routes functions
    /// Getting informations for widgets
    private func getInformations(req: Request) async throws -> Response {
        var information = Widgets(yearRevenues: 0, monthRevenues: 0, estimatesInCreation: 0, estimatesInWaiting: 0, invoiceInWaiting: 0, invoiceUnPaid: 0)
        
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        // Getting year revenues
        if let year = components.year,
           let revenues = try await YearRevenue.query(on: req.db).filter(\.$year == year).first() {
            information.yearRevenues = revenues.grandTotal
        }
        
        // Getting month revenues
        if let month = components.month,
           let year = components.year,
           let revenues = try await MonthRevenue.query(on: req.db).filter(\.$month == month).filter(\.$year == year).first() {
            information.monthRevenues = revenues.grandTotal
        }
        
        // Getting number of estimates in creation
        information.estimatesInCreation = try await Estimate.query(on: req.db).filter(\.$status == .inCreation).all().count
        
        // Getting number of estimates waiting
        information.estimatesInWaiting = try await Estimate.query(on: req.db).filter(\.$status == .sent).all().count
        
        // Getting number of invoice waiting
        information.invoiceInWaiting = try await Invoice.query(on: req.db).filter(\.$status == .sent).all().count
        
        // Getting number of invoice unpaid
        information.invoiceUnPaid = try await Invoice.query(on: req.db).filter(\.$status == .overdue).all().count
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(information)))
    }
}

