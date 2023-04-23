//
//  TaxController.swift
//  
//
//  Created by Kevin Bertrand on 11/01/2023.
//

import Fluent
import Vapor

struct TaxController: RouteCollection {
    // MARK: Properties
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let taxGroup = routes.grouped("tax")
        
        let tokenGroup = taxGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.get(":year", use: getTaxForYear)
    }
    
    // MARK: Routes functions
    /// Getting tax for selected year
    private func getTaxForYear(req: Request) async throws -> Response {
        guard let year = req.parameters.get("year", as: Int.self) else {
            throw Abort(.badRequest)
        }
        
        let rates = gettingYearTaxRate(year: year)
        
        let revenues = try await MonthRevenue.query(on: req.db)
            .filter(\.$year == year)
            .all()

        return GlobalFunctions.shared.formatResponse(status: .accepted,
                                                     body: .init(data: try JSONEncoder().encode(Tax(tax: calculateTax(revenues: revenues, rates: rates)))))
    }
    
    // MARK: Utilities functions
    /// Getting year tax rate
    private func gettingYearTaxRate(year: Int) -> [Int: Int] {
        let rates: [Int: [Int: Int]] = [
            2023: [
                10777: 0,
                27478: 11,
                78570: 30,
                168994: 41,
                Int.max: 45
            ]
        ]
        
        var currentRate: [Int: Int] = [:]
        
        for rate in rates {
            if rate.key >= year {
                currentRate = rate.value
            }
        }
        
        return currentRate
    }
    
    /// Calculating year tax
    private func calculateTax(revenues: [MonthRevenue], rates: [Int: Int]) -> Double {
        let numberOfMonths = revenues.count
        var sum = 0.0
        var sumTax = 0.0
        var isAllYear: Bool = false
        
        for revenue in revenues {
            sum += revenue.grandTotal
            
            if revenue.month == 12 {
                isAllYear = true
            }
        }
        
        if sum > 0 {
            if !isAllYear {
                let average = sum / Double(numberOfMonths)
                sum = average * 12
            }
            
            sum *= 0.66
            var keyIndex = 0
            var previousKey = 0
            
            for (key, value) in rates.sorted(by: {$0.key < $1.key}) {
                if sum > Double(key) {
                    if keyIndex == 0 {
                        sumTax += Double(key) * (Double(value) / 100.0)
                    } else if (Double(key) - Double(previousKey)) > 0 {
                        sumTax += (Double(key) - Double(previousKey)) * (Double(value) / 100.0)
                    }
                } else {
                    if keyIndex == 0 {
                        sumTax += Double(sum) * (Double(value) / 100.0)
                    } else if (Double(sum) - Double(previousKey)) > 0 {
                        sumTax += (Double(sum) - Double(previousKey)) * (Double(value) / 100.0)
                    }
                }
                
                previousKey = key
                keyIndex += 1
            }
        }
        
        return sumTax
    }
}

