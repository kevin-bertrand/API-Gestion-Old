//
//  YearRevenue.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class YearRevenue: Model, Content {
    // Name of the table
    static let schema: String = NameManager.YearRevenue.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.YearRevenue.year.rawValue.fieldKey)
    var year: Int
    
    @Field(key: NameManager.YearRevenue.totalServices.rawValue.fieldKey)
    var totalServices: Double
    
    @Field(key: NameManager.YearRevenue.totalMaterials.rawValue.fieldKey)
    var totalMaterials: Double
    
    @Field(key: NameManager.YearRevenue.totalDivers.rawValue.fieldKey)
    var totalDivers: Double
    
    @Field(key: NameManager.YearRevenue.grandTotal.rawValue.fieldKey)
    var grandTotal: Double
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, year: Int, totalServices: Double, totalMaterials: Double, totalDivers: Double, grandTotal: Double) {
        self.id = id
        self.year = year
        self.totalServices = totalServices
        self.totalMaterials = totalMaterials
        self.totalDivers = totalDivers
        self.grandTotal = grandTotal
    }
}
