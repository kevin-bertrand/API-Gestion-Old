//
//  File.swift
//  
//
//  Created by Kevin Bertrand on 24/11/2022.
//

import Foundation
import Fluent

enum NameManager {
    enum Enumeration: String {
        case personType = "person_type"
        case estimateStatus = "estimate_status"
        case invoiceStatus = "invoice_status"
        case productCategory = "product_category"
        case domain, gender, permissions, position
    }
    
    enum Address: String {
        case schema = "address"
        case roadName = "road_name"
        case streetNumber = "street_number"
        case zipCode = "zip_code"
        case complement, city, country, latitude, longitude, comment
    }
    
    enum Client: String {
        case schema = "client"
        case personType = "person_type"
        case addressId = "address_id"
        case firstname, lastname, company, phone, email, gender, siret, tva
    }
    
    enum Estimate: String {
        case schema = "estimate"
        case totalServices = "total_services"
        case totalMaterials = "total_materials"
        case totalDivers = "total_divers"
        case limitValidityDate = "limit_validity_date"
        case sendingDate = "sending_date"
        case clientId = "client_id"
        case isArchive = "is_archive"
        case reference, object, total, creation, update, status
    }
    
    enum InternalReference: String {
        case schema = "internal_reference"
        case reference = "ref"
        case estimateId = "estimate_id"
        case invoiceId = "invoice_id"
    }
    
    enum Invoice: String {
        case schema = "invoice"
        case totalServices = "total_services"
        case totalMaterials = "total_materials"
        case totalDivers = "total_divers"
        case grandTotal = "grand_total"
        case limitPaymentDate = "limit_payment_date"
        case facturationDate = "facturation_date"
        case delayDays = "delay_days"
        case totalDelay = "total_delay"
        case clientId = "client_id"
        case paymentId = "payment_id"
        case isArchive = "is_archive"
        case maxInterests = "maximum_interests"
        case limitMaxInterests = "limit_max_interests"
        case reference, object, total, creation, update, status, comment
    }
    
    enum MonthRevenue: String {
        case schema = "month_revenue"
        case totalServices = "total_services"
        case totalMaterials = "total_materials"
        case totalDivers = "total_divers"
        case grandTotal = "grand_total"
        case month, year
    }
    
    enum PaymentMethod: String {
        case schema = "payment_method"
        case title, iban, bic
    }
    
    enum Product: String {
        case schema = "product"
        case productCategory = "product_category"
        case domain, title, unity, price
    }
    
    enum ProductEstimate: String {
        case schema = "product_estimate"
        case productId = "product_id"
        case estimateId = "estimate_id"
        case quantity, reduction
    }
    
    enum ProductInvoice: String {
        case schema = "product_invoice"
        case productId = "product_id"
        case invoiceId = "invoice_id"
        case quantity, reduction
    }
    
    enum Staff: String {
        case schema = "staff"
        case profilePicture = "profile_picture"
        case passwordHash = "password_hash"
        case addressId = "address_id"
        case firstname, lastname, phone, email, gender, position, role, permissions
    }
    
    enum UserToken: String {
        case schema = "user_token"
        case staffId = "staff_id"
        case creation, value
    }
    
    enum YearRevenue: String {
        case schema = "year_revenue"
        case totalServices = "total_services"
        case totalMaterials = "total_materials"
        case totalDivers = "total_divers"
        case grandTotal = "grand_total"
        case year
    }
}
