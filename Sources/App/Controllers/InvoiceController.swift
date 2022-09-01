//
//  InvoiceController.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Fluent
import Vapor

struct InvoiceController: RouteCollection {
    // MARK: Properties
    var addressController: AddressController
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let invoiceGroup = routes.grouped("invoice")
        
        let tokenGroup = invoiceGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.get("reference", use: getInvoiceReference)
        tokenGroup.post(use: create)
        tokenGroup.patch(use: update)
        tokenGroup.get(use: getList)
        tokenGroup.get(":id", use: getInvoice)
    }
    
    // MARK: Routes functions
    /// Getting new invoice reference
    private func getInvoiceReference(req: Request) async throws -> Response {
        let invoices = try await Invoice.query(on: req.db).all()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let date = dateFormatter.string(from: Date())
        
        var number: String = "001"
        
        if invoices.count != 0 {
            let lastReference = invoices[invoices.count-1].reference.split(separator: "-")
            guard lastReference.count == 3 else { throw Abort(.internalServerError) }
            
            if lastReference[1] == date {
                guard let lastNumber = Int(lastReference[2]) else { throw Abort(.internalServerError) }
                let newNumber = "\(lastNumber+1)"
                number = ""
                
                for _ in 0..<(3-newNumber.count) { number.append("0")}
                
                number.append(newNumber)
            }
        }
        
        return formatResponse(status: .ok, body: try encodeBody("F-\(date)-\(number)"))
    }
    
    /// Create invoice
    private func create(req: Request) async throws -> Response {
        let newInvoice = try req.content.decode(Invoice.Create.self)
        try await Invoice(reference: newInvoice.reference,
                          internalReference: newInvoice.internalReference,
                          object: newInvoice.object,
                          totalServices: newInvoice.totalServices,
                          totalMaterials: newInvoice.totalMaterials,
                          totalDivers: newInvoice.totalDivers,
                          total: newInvoice.total,
                          reduction: newInvoice.reduction,
                          grandTotal: newInvoice.grandTotal,
                          status: newInvoice.status,
                          limitPayementDate: newInvoice.limitPayementDate,
                          clientID: newInvoice.clientID)
        .save(on: req.db)
        
        let invoice = try await Invoice.query(on: req.db)
            .filter(\.$reference == newInvoice.reference)
            .first()
        
        guard let invoice = invoice, let invoiceId = invoice.id else {
            throw Abort(.internalServerError)
        }
        
        for product in newInvoice.products {
            try await ProductInvoice(quantity: product.quantity, productID: product.productID, invoiceID: invoiceId).save(on: req.db)
        }
        
        return formatResponse(status: .created, body: try encodeBody("\(invoice.reference) is created!"))
    }
    
    /// Update invoice
    private func update(req: Request) async throws -> Response {
        let updatedInvoice = try req.content.decode(Invoice.Update.self)
        
        guard let invoice = try await Invoice.find(updatedInvoice.id, on: req.db), !invoice.isArchive else {
            throw Abort(.notAcceptable)
        }
        
        print(updatedInvoice.status)
        
        try await Invoice.query(on: req.db)
            .set(\.$object, to: updatedInvoice.object)
            .set(\.$totalServices, to: updatedInvoice.totalServices)
            .set(\.$totalMaterials, to: updatedInvoice.totalMaterials)
            .set(\.$totalDivers, to: updatedInvoice.totalDivers)
            .set(\.$total, to: updatedInvoice.total)
            .set(\.$reduction, to: updatedInvoice.reduction)
            .set(\.$grandTotal, to: updatedInvoice.grandTotal)
            .set(\.$status, to: updatedInvoice.status)
            .set(\.$limitPayementDate, to: updatedInvoice.limitPayementDate ?? Date().addingTimeInterval(2592000))
            .set(\.$isArchive, to: updatedInvoice.status == .payed ? true : false)
            .filter(\.$reference == updatedInvoice.reference)
            .update()
        
        for product in updatedInvoice.products {
            if product.quantity == 0 {
                try await ProductInvoice.query(on: req.db)
                    .filter(\.$product.$id == product.productID)
                    .filter(\.$invoice.$id == updatedInvoice.id)
                    .delete()
            } else {
                if let _ = try await ProductInvoice.query(on: req.db)
                    .filter(\.$product.$id == product.productID)
                    .filter(\.$invoice.$id == updatedInvoice.id)
                    .first() {
                    try await ProductInvoice.query(on: req.db)
                        .set(\.$quantity, to: product.quantity)
                        .filter(\.$product.$id == product.productID)
                        .filter(\.$invoice.$id == updatedInvoice.id)
                        .update()
                } else {
                    try await ProductInvoice(quantity: product.quantity, productID: product.productID, invoiceID: updatedInvoice.id).save(on: req.db)
                }
            }
        }
        
        if let invoice = try await Invoice.find(updatedInvoice.id, on: req.db), invoice.isArchive == true {
            let reference = invoice.reference.split(separator: "-")
            
            guard reference.count == 3,
                  let year = Int(String(reference[1].dropLast(2))),
                  let month = Int(String(reference[1].dropFirst(4))) else {
                throw Abort(.internalServerError)
            }
            
            try await addToYearRevenue(year: year,
                                       totalServices: invoice.totalServices,
                                       totalMaterial: invoice.totalMaterials,
                                       totalDivers: invoice.totalDivers,
                                       grandTotal: invoice.grandTotal, in: req)
            try await addToMonthRevenue(month: month,
                                        year: year,
                                        totalServices: invoice.totalServices,
                                        totalMaterial: invoice.totalMaterials,
                                        totalDivers: invoice.totalDivers,
                                        grandTotal: invoice.grandTotal,
                                        in: req)
        }
        
        return formatResponse(status: .ok, body: .empty)
    }
    /// Getting invoice list
    private func getList(req: Request) async throws -> Response {
        let invoices = try await Invoice.query(on: req.db)
            .with(\.$client)
            .all()
        
        return formatResponse(status: .ok, body: try encodeBody(formatInvoiceSummaray(invoices)))
    }
    
    /// Getting invoice
    private func getInvoice(req: Request) async throws -> Response {
        let id = req.parameters.get("id", as: UUID.self)
        
        guard let id = id, let invoice = try await Invoice.find(id, on: req.db), let client = try await Client.find(invoice.$client.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let productsInvoice = try await ProductInvoice.query(on: req.db).filter(\.$invoice.$id == id).all()
        var products: [Product.Informations] = []
        
        for productInvoice in productsInvoice {
            guard let product = try await Product.find(productInvoice.$product.id, on: req.db) else { throw Abort(.notAcceptable) }
            products.append(Product.Informations(quantity: productInvoice.quantity,
                                                 title: product.title,
                                                 unity: product.unity,
                                                 domain: product.domain,
                                                 productCategory: product.productCategory,
                                                 price: product.price))
        }
        
        let invoiceInformations = Invoice.Informations(id: id,
                                                       reference: invoice.reference,
                                                       internalReference: invoice.internalReference,
                                                       object: invoice.object,
                                                       totalServices: invoice.totalServices,
                                                       totalMaterials: invoice.totalMaterials,
                                                       totalDivers: invoice.totalDivers,
                                                       total: invoice.total,
                                                       reduction: invoice.reduction,
                                                       grandTotal: invoice.grandTotal,
                                                       status: invoice.status,
                                                       limitPayementDate: invoice.limitPayementDate,
                                                       client: Client.Informations(firstname: client.firstname,
                                                                                   lastname: client.lastname,
                                                                                   company: client.company,
                                                                                   phone: client.phone,
                                                                                   email: client.email,
                                                                                   personType: client.personType,
                                                                                   gender: client.gender,
                                                                                   siret: client.siret,
                                                                                   tva: client.tva,
                                                                                   address: try await addressController.getAddressFromId(client.$address.id, for: req)),
                                                       products: products,
                                                       isArchive: invoice.isArchive)
        
        return formatResponse(status: .ok, body: try encodeBody(invoiceInformations))
    }
    // MARK: Utilities functions
    /// Getting the connected user
    private func getUserAuthFor(_ req: Request) throws -> Staff {
        return try req.auth.require(Staff.self)
    }
    
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
    
    /// Format invoice summary
    private func formatInvoiceSummaray(_ invoices: [Invoice]) -> [Invoice.Summary] {
        var invoiceSummary: [Invoice.Summary] = []
        
        for invoice in invoices {
            if let client = invoice.$client.value {
                invoiceSummary.append(Invoice.Summary(id: invoice.id,
                                                      client: Client.Summary(firstname: client.firstname,
                                                                             lastname: client.lastname,
                                                                             company: client.company),
                                                      reference: invoice.reference,
                                                      grandTotal: invoice.grandTotal,
                                                      status: invoice.status,
                                                      limitPayementDate: invoice.limitPayementDate,
                                                      isArchive: invoice.isArchive))
            }
        }
        
        return invoiceSummary
    }
    
    /// Adding invoice to year revenue
    private func addToYearRevenue(year: Int, totalServices: Double, totalMaterial: Double, totalDivers: Double, grandTotal: Double, in req: Request) async throws {
        if let record = try await YearRevenue.query(on: req.db).filter(\.$year == year).first() {
            try await YearRevenue.query(on: req.db)
                .set(\.$totalServices, to: (record.totalServices + totalServices))
                .set(\.$totalMaterials, to: (record.totalMaterials + totalMaterial))
                .set(\.$grandTotal, to: (record.grandTotal + grandTotal))
                .filter(\.$year == year)
                .update()
        } else {
            try await YearRevenue(year: year, totalServices: totalServices, totalMaterials: totalMaterial, totalDivers: totalDivers, grandTotal: grandTotal).save(on: req.db)
        }
    }
    
    /// Adding invoice to month revenue
    private func addToMonthRevenue(month: Int, year: Int, totalServices: Double, totalMaterial: Double, totalDivers: Double, grandTotal: Double, in req: Request) async throws {
        if let record = try await MonthRevenue.query(on: req.db).filter(\.$year == year).filter(\.$month == month).first() {
            try await MonthRevenue.query(on: req.db)
                .set(\.$totalServices, to: (record.totalServices + totalServices))
                .set(\.$totalMaterials, to: (record.totalMaterials + totalMaterial))
                .set(\.$grandTotal, to: (record.grandTotal + grandTotal))
                .filter(\.$year == year)
                .filter(\.$month == month)
                .update()
        } else {
            try await MonthRevenue(month: month, year: year, totalServices: totalServices, totalMaterials: totalMaterial, totalDivers: totalDivers, grandTotal: grandTotal).save(on: req.db)
        }
    }
}
