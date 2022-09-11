//
//  EstimateController.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Fluent
import Vapor

struct EstimateController: RouteCollection {
    // MARK: Properties
    var addressController: AddressController
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let estimateGroup = routes.grouped("estimate")
        
        let tokenGroup = estimateGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.get("reference", use: getEstimateReference)
        tokenGroup.get("list", use: getList)
        tokenGroup.get("list", ":filter", use: getList)
        tokenGroup.get(":id", use: getEstimate)
        tokenGroup.get("pdf", ":id", use: pdf)
        tokenGroup.post(use: create)
        tokenGroup.patch(use: update)
        tokenGroup.post("toInvoice", ":reference", use: exportToInvoice)
    }
    
    // MARK: Routes functions
    /// Getting new estimate reference
    private func getEstimateReference(req: Request) async throws -> Response {
        let estimates = try await Estimate.query(on: req.db)
            .all()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMM"
        let date = dateFormatter.string(from: Date())
        
        var number: String = "001"
        
        if estimates.count != 0 {
            let lastReference = estimates[estimates.count-1].reference.split(separator: "-")
            guard lastReference.count == 3 else { throw Abort(.internalServerError) }
            
            if lastReference[1] == date {
                guard let lastNumber = Int(lastReference[2]) else { throw Abort(.internalServerError) }
                let newNumber = "\(lastNumber+1)"
                number = ""
                
                for _ in 0..<(3-newNumber.count) { number.append("0") }
                
                number.append(newNumber)
            }
        }
        
        return formatResponse(status: .ok, body: try encodeBody("D-\(date)-\(number)"))
    }
    
    /// Create
    private func create(req: Request) async throws -> Response {
        let newEstimate = try req.content.decode(Estimate.Create.self)
        
        guard newEstimate.reference != "" else { throw Abort(.notAcceptable)}
        
        try await Estimate(reference: newEstimate.reference,
                           internalReference: newEstimate.internalReference,
                           object: newEstimate.object,
                           totalServices: newEstimate.totalServices,
                           totalMaterials: newEstimate.totalMaterials,
                           totalDivers: newEstimate.totalDivers,
                           total: newEstimate.total,
                           reduction: newEstimate.reduction,
                           grandTotal: newEstimate.grandTotal,
                           status: newEstimate.status,
                           limitValidityDate: newEstimate.limitValidifyDate ?? nil,
                           clientID: newEstimate.clientID)
        .save(on: req.db)
        
        let estimate = try await Estimate.query(on: req.db)
            .filter(\.$reference == newEstimate.reference)
            .first()
        
        guard let estimate = estimate else {
            throw Abort(.internalServerError)
        }
        
        for product in newEstimate.products {
            try await ProductEstimate(quantity: product.quantity, productID: product.productID, estimateID: try estimate.requireID()).save(on: req.db)
        }
        
        return formatResponse(status: .created, body: .empty)
    }
    
    /// Update lines
    private func update(req: Request) async throws -> Response {
        let updateEstimate = try req.content.decode(Estimate.Update.self)
        
        guard let estimate = try await Estimate.find(updateEstimate.id, on: req.db), !estimate.isArchive else {
            throw Abort(.notAcceptable)
        }
        
        try await Estimate.query(on: req.db)
            .set(\.$object, to: updateEstimate.object)
            .set(\.$totalServices, to: updateEstimate.totalServices)
            .set(\.$totalMaterials, to: updateEstimate.totalMaterials)
            .set(\.$totalDivers, to: updateEstimate.totalDivers)
            .set(\.$total, to: updateEstimate.total)
            .set(\.$reduction, to: updateEstimate.reduction)
            .set(\.$grandTotal, to: updateEstimate.grandTotal)
            .set(\.$status, to: updateEstimate.status)
            .set(\.$limitValidityDate, to: updateEstimate.limitValidifyDate ?? Date().addingTimeInterval(2592000))
            .filter(\.$reference == updateEstimate.reference)
            .update()
        
        for product in updateEstimate.products {
            if product.quantity == 0 {
                try await ProductEstimate.query(on: req.db)
                    .filter(\.$product.$id == product.productID)
                    .filter(\.$estimate.$id == updateEstimate.id)
                    .delete()
            } else {
                let firstMatch = try await ProductEstimate.query(on: req.db)
                    .filter(\.$product.$id == product.productID)
                    .filter(\.$estimate.$id == updateEstimate.id)
                    .first()
                
                if firstMatch != nil {
                    try await ProductEstimate.query(on: req.db)
                        .set(\.$quantity, to: product.quantity)
                        .filter(\.$product.$id == product.productID)
                        .filter(\.$estimate.$id == updateEstimate.id)
                        .update()
                } else {
                    try await ProductEstimate(quantity: product.quantity, productID: product.productID, estimateID: updateEstimate.id).save(on: req.db)
                }
            }
        }
        
        return formatResponse(status: .ok, body: .empty)
    }
    
    /// Getting invoice list
    private func getList(req: Request) async throws -> Response {
        let filters = req.parameters.get("filter", as: Int.self)
        
        let estimates: [Estimate.Summary]
        
        if let filters = filters {
            let estimatesCount = try await Estimate.query(on: req.db).count()
            let min = (estimatesCount - filters) < 0 ? 0 : (estimatesCount - filters)
            
            estimates = formatEstimatesSummary(req: req,
                                               estimates: try await Estimate.query(on: req.db).with(\.$client).range(min..<estimatesCount).all())
        } else {
            estimates = try await getAllEstimates(req: req)
        }
        
        return formatResponse(status: .ok, body: try encodeBody(estimates))
    }
    
    /// Get estimate
    private func getEstimate(req: Request) async throws -> Response {
        let id = req.parameters.get("id", as: UUID.self)
        
        guard let id = id,
              let estimate = try await Estimate.find(id, on: req.db),
              let client = try await Client.find(estimate.$client.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let productEstimates = try await ProductEstimate.query(on: req.db).filter(\.$estimate.$id == id).all()
        var products: [Product.Informations] = []
        
        for productEstimate in productEstimates {
            guard let product = try await Product.find(productEstimate.$product.id, on: req.db), let productId = product.id else { throw Abort(.notAcceptable) }
            products.append(Product.Informations(id: productId,
                                                 quantity: productEstimate.quantity,
                                                 title: product.title,
                                                 unity: product.unity,
                                                 domain: product.domain,
                                                 productCategory: product.productCategory,
                                                 price: product.price))
        }
        
        let estimateInformations = Estimate.Informations(id: id,
                                                         reference: estimate.reference,
                                                         internalReference: estimate.internalReference,
                                                         object: estimate.object,
                                                         totalServices: estimate.totalServices,
                                                         totalMaterials: estimate.totalMaterials,
                                                         totalDivers: estimate.totalDivers,
                                                         total: estimate.total,
                                                         reduction: estimate.reduction,
                                                         grandTotal: estimate.grandTotal,
                                                         status: estimate.status,
                                                         limitValidityDate: estimate.limitValidityDate,
                                                         isArchive: estimate.isArchive,
                                                         client: Client.Informations(id: client.id,
                                                                                     firstname: client.firstname,
                                                                                     lastname: client.lastname,
                                                                                     company: client.company,
                                                                                     phone: client.phone,
                                                                                     email: client.email,
                                                                                     personType: client.personType,
                                                                                     gender: client.gender,
                                                                                     siret: client.siret,
                                                                                     tva: client.tva,
                                                                                     address: try await addressController.getAddressFromId(client.$address.id, for: req)),
                                                         products: products)
        
        return formatResponse(status: .ok, body: try encodeBody(estimateInformations))
    }
    
    /// Export estimate to invoice
    private func exportToInvoice(req: Request) async throws -> Response {
        let estimateRef = req.parameters.get("reference")
        let serverIP = Environment.get("SERVER_HOSTNAME") ?? "127.0.0.1"
        let serverPort = Environment.get("SERVER_PORT").flatMap(Int.init(_:)) ?? 8080
        
        guard let estimateRef = estimateRef,
              let estimate = try await Estimate.query(on: req.db).filter(\.$reference == estimateRef).first(),
              let estimateId = estimate.id else {
            throw Abort(.notFound)
        }
        
        let invoiceRefResponse = try await req.client.get("http://\(serverIP):\(serverPort)/invoice/reference", headers: req.headers)
        
        guard var invoiceRef = invoiceRefResponse.body, let data = invoiceRef.readData(length: invoiceRef.readableBytes) else {
            throw Abort(.internalServerError)
        }
        
        let reference = try JSONDecoder().decode(String.self, from: data)
        
        let products = try await ProductEstimate.query(on: req.db)
            .filter(\.$estimate.$id == estimateId)
            .all()
        
        var newInvoiceProducts: [Product.Create] = []
        
        for product in products {
            newInvoiceProducts.append(.init(productID: product.$product.id, quantity: product.quantity))
        }
        
        let newInvoice = Invoice.Create(reference: reference,
                                        internalReference: estimate.internalReference,
                                        object: estimate.object,
                                        totalServices: estimate.totalServices,
                                        totalMaterials: estimate.totalMaterials,
                                        totalDivers: estimate.totalDivers,
                                        total: estimate.total,
                                        reduction: estimate.reduction,
                                        grandTotal: estimate.grandTotal,
                                        status: .inCreation,
                                        limitPayementDate: nil,
                                        clientID: estimate.$client.id,
                                        paymentID: nil,
                                        products: newInvoiceProducts)
        
        let addInvoiceResponse = try await req.client.post("http://\(serverIP):\(serverPort)/invoice",
                                                           headers: req.headers,
                                                           content: newInvoice)
        
        guard let responseBody = addInvoiceResponse.body else {
            throw Abort(.internalServerError)
        }
        
        try await Estimate.query(on: req.db)
            .set(\.$isArchive, to: true)
            .set(\.$status, to: .accepted)
            .filter(\.$id == estimateId)
            .update()
        
        return formatResponse(status: addInvoiceResponse.status, body: .init(buffer: responseBody))
    }
    
    /// Generate a PDF from the Database for a selected ID
    private func pdf(req: Request) async throws -> Response {
        let document = Document(margins: 15)
        let id = req.parameters.get("id", as: UUID.self)
        guard let id = id, let estimate = try await Estimate.find(id, on: req.db), let client = try await Client.find(estimate.$client.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let productsEstimate = try await ProductEstimate.query(on: req.db).filter(\.$estimate.$id == id).all()
        var products: [Product.Informations] = []
        
        for productEstimate in productsEstimate {
            guard let product = try await Product.find(productEstimate.$product.id, on: req.db), let productId = product.id else { throw Abort(.notAcceptable) }
            products.append(Product.Informations(id: productId,
                                                 quantity: productEstimate.quantity,
                                                 title: product.title,
                                                 unity: product.unity,
                                                 domain: product.domain,
                                                 productCategory: product.productCategory,
                                                 price: product.price))
        }
        
        let address = try await addressController.getAddressFromId(client.$address.id, for: req)
        
        var clientName: String = ""
        
        if let firstname = client.firstname,
           let lastname = client.lastname {
            clientName = "\((client.gender  == .man ? "M. " : client.gender == .woman ? "Mme." : ""))\(firstname) \(lastname.uppercased())"
        }
        
        if let company = client.company {
            if !clientName.isEmpty {
                clientName.append(" - ")
            }
            clientName.append(company)
        }
        
        let materialsProducts = products.filter({$0.productCategory == .material}).map({ return [$0.title, "\($0.price.twoDigitPrecision) \($0.unity ?? "")", $0.quantity.twoDigitPrecision, "\(($0.quantity * $0.price).twoDigitPrecision) €", "0.00 %"]})
        let servicesProducts = products.filter({$0.productCategory == .service}).map({ return [$0.title, "\($0.price.twoDigitPrecision) \($0.unity ?? "")", $0.quantity.twoDigitPrecision, "\(($0.quantity * $0.price).twoDigitPrecision) €", "0.00 %"]})
        let diversProducts = products.filter({$0.productCategory == .divers}).map({ return [$0.title, "\($0.price.twoDigitPrecision) \($0.unity ?? "")", $0.quantity.twoDigitPrecision, "\(($0.quantity * $0.price).twoDigitPrecision) €", "0.00 %"]})
        
        let page = req.view.render("estimate", Estimate.PDF(creationDate: (estimate.creation ?? Date()).formatted(date: .numeric, time: .omitted),
                                                            reference: estimate.reference,
                                                            clientName: clientName,
                                                            clientAddress: "\(address.streetNumber) \(address.roadName)",
                                                            clientCity: "\(address.zipCode), \(address.city) - \(address.country)",
                                                            internalReference: estimate.internalReference,
                                                            object: estimate.object,
                                                            total: estimate.grandTotal.twoDigitPrecision,
                                                            materialsProducts: materialsProducts,
                                                            servicesProducts: servicesProducts,
                                                            diversProducts: diversProducts,
                                                            totalServices: estimate.totalServices.twoDigitPrecision,
                                                            totalMaterials: estimate.totalMaterials.twoDigitPrecision,
                                                            totalDivers: estimate.totalDivers.twoDigitPrecision,
                                                            limitDate: estimate.limitValidityDate.formatted(date: .numeric, time: .omitted),
                                                            tva: client.tva ?? "",
                                                            siret: client.siret ?? "",
                                                            hasTva: client.tva != nil,
                                                            hasSiret: client.siret != nil))
        
        let pages = try [page]
            .flatten(on: req.eventLoop)
            .map { views in
                views.map { Page($0.data) }
            }.wait()
        
        document.pages = pages
        let pdf = try await document.generatePDF(on: req.application.threadPool, eventLoop: req.eventLoop, title: estimate.reference)
        
        return Response(status: .ok, headers: HTTPHeaders([("Content-Type", "application/pdf")]), body: .init(data: pdf))
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
    private func encodeBody(_ body: any Encodable) throws -> Response.Body {
        return .init(data: try JSONEncoder().encode(body))
    }
    
    /// Getting all estimates
    private func getAllEstimates(req: Request) async throws -> [Estimate.Summary] {
        return formatEstimatesSummary(req: req, estimates: try await Estimate.query(on: req.db).with(\.$client).all())
    }
    
    /// Format estimate summary
    private func formatEstimatesSummary(req: Request, estimates: [Estimate]) -> [Estimate.Summary] {
        var estimateSummary: [Estimate.Summary] = []
        
        for estimate in estimates {
            if let client = estimate.$client.value {
                estimateSummary.append(Estimate.Summary(id: estimate.id,
                                                        client: Client.Summary(firstname: client.firstname,
                                                                               lastname: client.lastname,
                                                                               company: client.company),
                                                        reference: estimate.reference,
                                                        grandTotal: estimate.grandTotal,
                                                        status: estimate.status,
                                                        limitValidifyDate: estimate.limitValidityDate,
                                                        isArchive: estimate.isArchive))
            }
        }
        
        return estimateSummary
    }
}
