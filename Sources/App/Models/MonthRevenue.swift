//
//  MonthRevenue.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class MonthRevenue: Model, Content {
    // Name of the table
    static let schema: String = NameManager.MonthRevenue.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.MonthRevenue.month.rawValue.fieldKey)
    var month: Int
    
    @Field(key: NameManager.MonthRevenue.year.rawValue.fieldKey)
    var year: Int
    
    @Field(key: NameManager.MonthRevenue.totalServices.rawValue.fieldKey)
    var totalServices: Double
    
    @Field(key: NameManager.MonthRevenue.totalMaterials.rawValue.fieldKey)
    var totalMaterials: Double
    
    @Field(key: NameManager.MonthRevenue.totalDivers.rawValue.fieldKey)
    var totalDivers: Double
    
    @Field(key: NameManager.MonthRevenue.grandTotal.rawValue.fieldKey)
    var grandTotal: Double
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, month: Int, year: Int, totalServices: Double, totalMaterials: Double, totalDivers: Double, grandTotal: Double) {
        self.id = id
        self.month = month
        self.year = year
        self.totalServices = totalServices
        self.totalMaterials = totalMaterials
        self.totalDivers = totalDivers
        self.grandTotal = grandTotal
    }
}
