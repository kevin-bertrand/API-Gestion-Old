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
        tokenGroup.post("list", use: getList)
        tokenGroup.get("list", ":filter", use: getList)
        tokenGroup.get(":id", use: getEstimate)
        tokenGroup.get("pdf", ":id", use: pdf)
        tokenGroup.post(use: create)
        tokenGroup.patch(use: update)
        tokenGroup.patch("status", ":reference", ":status", use: updateStatus)
        tokenGroup.post("toInvoice", ":reference", use: exportToInvoice)
    }
    
    // MARK: Routes functions
    /// Getting new estimate reference
    private func getEstimateReference(req: Request) async throws -> Response {
        let estimates = try await Estimate.query(on: req.db)
            .sort(\.$reference)
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
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode("D-\(date)-\(number)")))
    }
    
    /// Create
    private func create(req: Request) async throws -> Response {
        let newEstimate = try req.content.decode(Estimate.Create.self)
        
        guard newEstimate.reference != "" else { throw Abort(.notAcceptable)}
        
        try await Estimate(reference: newEstimate.reference,
                           object: newEstimate.object,
                           totalServices: newEstimate.totalServices,
                           totalMaterials: newEstimate.totalMaterials,
                           totalDivers: newEstimate.totalDivers,
                           total: newEstimate.total,
                           status: newEstimate.status,
                           limitValidityDate: newEstimate.limitValidifyDate ?? nil,
                           sendingDate: Date(),
                           clientID: newEstimate.clientID)
        .save(on: req.db)
        
        let estimate = try await Estimate.query(on: req.db)
            .filter(\.$reference == newEstimate.reference)
            .first()
        
        guard let estimate = estimate else {
            throw Abort(.internalServerError)
        }
        
        try await InternalReference(ref: newEstimate.internalReference, estimateID: estimate.requireID()).save(on: req.db)
        
        for product in newEstimate.products {
            try await ProductEstimate(quantity: product.quantity, productID: product.productID, estimateID: try estimate.requireID()).save(on: req.db)
        }
        
        try await saveAsPDF(on: req, id: estimate.id)
        
        return GlobalFunctions.shared.formatResponse(status: .created, body: .empty)
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
            .set(\.$status, to: updateEstimate.status)
            .set(\.$creation, to: updateEstimate.creationDate)
            .set(\.$limitValidityDate, to: updateEstimate.limitValidifyDate ?? Date().addingTimeInterval(2592000))
            .set(\.$sendingDate, to: updateEstimate.sendingDate)
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
                        .set(\.$reduction, to: product.reduction)
                        .filter(\.$product.$id == product.productID)
                        .filter(\.$estimate.$id == updateEstimate.id)
                        .update()
                } else {
                    try await ProductEstimate(quantity: product.quantity, reduction: product.reduction, productID: product.productID, estimateID: updateEstimate.id).save(on: req.db)
                }
            }
        }
        
        try await InternalReference.query(on: req.db)
            .set(\.$ref, to: updateEstimate.internalReference)
            .filter(\.$estimate.$id == updateEstimate.id)
            .update()
        
        try await saveAsPDF(on: req, id: estimate.id)
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Getting estimate list
    private func getList(req: Request) async throws -> Response {
        let dateFilter = try req.content.decode(Estimate.Getting.self)
        let startDate = (dateFilter.startDate ?? "").toDate
        let endDate = (dateFilter.endDate ?? "").toDate
        
        let estimates: [Estimate.Summary]
        
        if startDate != nil && endDate != nil {
            estimates = formatEstimateSummary(try await Estimate.query(on: req.db)
                .with(\.$client)
                .filter(\.$limitValidityDate >= startDate!)
                .filter(\.$limitValidityDate <= endDate!)
                .all())
        } else if startDate != nil {
            estimates = formatEstimateSummary(try await Estimate.query(on: req.db)
                .with(\.$client)
                .filter(\.$limitValidityDate >= startDate!)
                .all())
        } else if endDate != nil {
            estimates = formatEstimateSummary(try await Estimate.query(on: req.db)
                .with(\.$client)
                .filter(\.$limitValidityDate <= endDate!)
                .all())
        } else {
            estimates = formatEstimateSummary(try await Estimate.query(on: req.db)
                .with(\.$client)
                .all())
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(estimates)))
    }
    
    /// Get estimate
    private func getEstimate(req: Request) async throws -> Response {
        let id = req.parameters.get("id", as: UUID.self)
        
        guard let id = id,
              let estimate = try await Estimate.find(id, on: req.db),
              let client = try await Client.find(estimate.$client.id, on: req.db),
              let internalRef = try await InternalReference.query(on: req.db).filter(\.$estimate.$id == estimate.requireID()).first()?.ref else {
            throw Abort(.notFound)
        }
        
        let productEstimates = try await ProductEstimate.query(on: req.db).filter(\.$estimate.$id == id).all()
        var products: [Product.Informations] = []
        
        for productEstimate in productEstimates {
            guard let product = try await Product.find(productEstimate.$product.id, on: req.db), let productId = product.id else { throw Abort(.notAcceptable) }
            products.append(Product.Informations(id: productId,
                                                 quantity: productEstimate.quantity,
                                                 reduction: productEstimate.reduction,
                                                 title: product.title,
                                                 unity: product.unity,
                                                 domain: product.domain,
                                                 productCategory: product.productCategory,
                                                 price: product.price))
        }
        
        let estimateInformations = Estimate.Informations(id: id,
                                                         reference: estimate.reference,
                                                         internalReference: internalRef,
                                                         object: estimate.object,
                                                         totalServices: estimate.totalServices,
                                                         totalMaterials: estimate.totalMaterials,
                                                         totalDivers: estimate.totalDivers,
                                                         total: estimate.total,
                                                         status: estimate.status,
                                                         limitValidityDate: estimate.limitValidityDate,
                                                         creationDate: estimate.creation,
                                                         sendingDate: estimate.sendingDate,
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
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(estimateInformations)))
    }
    
    /// Update status of an estimate
    private func updateStatus(req: Request) async throws -> Response {
        let status = req.parameters.get("status", as: String.self)
        let reference = req.parameters.get("reference")
        
        guard let status,
              let reference,
              let status = EstimateStatus(rawValue: status) else {
            throw Abort(.notAcceptable)
        }
        
        try await Estimate.query(on: req.db)
            .filter(\.$reference == reference)
            .set(\.$status, to: status)
            .update()
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Export estimate to invoice
    private func exportToInvoice(req: Request) async throws -> Response {
        let estimateRef = req.parameters.get("reference")
        let serverIP = Environment.get("SERVER_HOSTNAME") ?? "127.0.0.1"
        let serverPort = Environment.get("SERVER_PORT").flatMap(Int.init(_:)) ?? 8080
        
        guard let estimateRef = estimateRef,
              let estimate = try await Estimate.query(on: req.db).filter(\.$reference == estimateRef).first(),
              let estimateId = estimate.id,
              let internalRef = try await InternalReference.query(on: req.db).filter(\.$estimate.$id == estimateId).first()?.ref else {
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
            newInvoiceProducts.append(.init(productID: product.$product.id,
                                            quantity: product.quantity,
                                            reduction: product.reduction))
        }
        
        let newInvoice = Invoice.Create(reference: reference,
                                        internalReference: internalRef,
                                        object: estimate.object,
                                        totalServices: estimate.totalServices,
                                        totalMaterials: estimate.totalMaterials,
                                        totalDivers: estimate.totalDivers,
                                        total: estimate.total,
                                        grandTotal: estimate.total,
                                        status: .inCreation,
                                        limitPayementDate: nil,
                                        clientID: estimate.$client.id,
                                        paymentID: nil,
                                        comment: nil,
                                        products: newInvoiceProducts,
                                        limitMaximumInterests: nil,
                                        maxInterests: nil)
        
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
        
        return GlobalFunctions.shared.formatResponse(status: addInvoiceResponse.status, body: .init(buffer: responseBody))
    }
    
    /// Generate a PDF from the Database for a selected ID
    private func pdf(req: Request) async throws -> Response {
        let id = req.parameters.get("id", as: UUID.self)
        
        guard let estimate = try await Estimate.find(id, on: req.db) else { throw Abort(.notAcceptable) }
        
        var file = ByteBuffer()
        
        for _ in 0..<3 {
            do {
                file = try await req.fileio.collectFile(at: "/home/vapor/Gestion-server/Public/\(estimate.reference).pdf")
                return Response(status: .ok, headers: HTTPHeaders([("Content-Type", "application/pdf")]), body: .init(buffer: file))
            } catch {
                try await saveAsPDF(on: req, id: id)
            }
        }
        
        throw Abort(.internalServerError)
    }
    
    // MARK: Utilities functions
    /// Getting all estimates
    private func getAllEstimates(req: Request) async throws -> [Estimate.Summary] {
        return formatEstimatesSummary(req: req, estimates: try await Estimate.query(on: req.db).with(\.$client).sort(\.$reference).all())
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
                                                        total: estimate.total,
                                                        status: estimate.status,
                                                        limitValidifyDate: estimate.limitValidityDate,
                                                        isArchive: estimate.isArchive))
            }
        }
        
        return estimateSummary
    }
    
    /// Getting product list for PDF
    private func getPdfProductList(_ products: [Product.Informations], for category: ProductCategory) -> [[String]] {
        return (
            products
                .filter({$0.productCategory == category})
                .map({ product in
                    let total = product.price * product.quantity
                    
                    return  [product.title,
                             "\(product.price.twoDigitPrecision) \(product.unity ?? "")",
                             "0 %",
                             product.quantity.twoDigitPrecision,
                             "\(total.twoDigitPrecision) €",
                             "\(total.twoDigitPrecision) €"]
                })
        )
    }
    
    /// Save the invoice as PDF
    private func saveAsPDF(on req: Request, id: UUID?) async throws {
        let document = Document(margins: 15)

        guard let id = id,
              let estimate = try await Estimate.find(id, on: req.db),
              let client = try await Client.find(estimate.$client.id, on: req.db),
              let internalRef = try await InternalReference.query(on: req.db).filter(\.$estimate.$id == estimate.requireID()).first()?.ref else {
            throw Abort(.notFound)
        }
        
        let productsEstimate = try await ProductEstimate.query(on: req.db).filter(\.$estimate.$id == id).all()
        var products: [Product.Informations] = []
        
        for productEstimate in productsEstimate {
            guard let product = try await Product.find(productEstimate.$product.id, on: req.db), let productId = product.id else { throw Abort(.notAcceptable) }
            products.append(Product.Informations(id: productId,
                                                 quantity: productEstimate.quantity,
                                                 reduction: productEstimate.reduction,
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
        
        let materialsProducts = getPdfProductList(products, for: .material)
        let servicesProducts = getPdfProductList(products, for: .service)
        let diversProducts = getPdfProductList(products, for: .divers)
        
        let page = req.view.render("estimate", Estimate.PDF(creationDate: Date().dateOnly,
                                                            reference: estimate.reference,
                                                            clientName: clientName,
                                                            clientAddress: "\(address.streetNumber) \(address.roadName)",
                                                            clientCity: "\(address.zipCode), \(address.city)",
                                                            clientCountry: address.country,
                                                            internalReference: internalRef,
                                                            object: estimate.object,
                                                            total: estimate.total.twoDigitPrecision,
                                                            materialsProducts: materialsProducts,
                                                            servicesProducts: servicesProducts,
                                                            diversProducts: diversProducts,
                                                            totalServices: estimate.totalServices.twoDigitPrecision,
                                                            totalMaterials: estimate.totalMaterials.twoDigitPrecision,
                                                            totalDivers: estimate.totalDivers.twoDigitPrecision,
                                                            limitDate: estimate.limitValidityDate.dateOnly,
                                                            sendingDate: estimate.sendingDate.dateOnly,
                                                            tva: client.tva ?? "",
                                                            siret: client.siret ?? "",
                                                            hasTva: client.tva != nil,
                                                            hasSiret: client.siret != nil))
        
        let pages = try [page]
            .flatten(on: req.eventLoop)
            .map({ views in
                views.map { view in
                    Page(view.data)
                }
            }).wait()
        
        document.pages = pages
        let pdf = try await document.generatePDF(on: req.application.threadPool, eventLoop: req.eventLoop, title: estimate.reference)
                
        try await req.fileio.writeFile(ByteBuffer(data: pdf), at: "/home/vapor/Gestion-server/Public/\(estimate.reference).pdf")
    }
    
    /// Format estimate summary
    private func formatEstimateSummary(_ estimates: [Estimate]) -> [Estimate.Summary] {
        var estimatesSummary: [Estimate.Summary] = []
        
        for estimate in estimates {
            if let client = estimate.$client.value {
                estimatesSummary.append(.init(id: estimate.id,
                                              client: Client.Summary(firstname: client.firstname,
                                                                     lastname: client.lastname,
                                                                     company: client.company),
                                              reference: estimate.reference,
                                              total: estimate.total,
                                              status: estimate.status,
                                              limitValidifyDate: estimate.limitValidityDate,
                                              isArchive: estimate.isArchive))
            }
        }
        
        return estimatesSummary
    }
}
