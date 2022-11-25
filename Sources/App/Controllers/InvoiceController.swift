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
        tokenGroup.patch("paied", ":id", use: isPaied)
        tokenGroup.patch(use: update)
        tokenGroup.get(use: getList)
        tokenGroup.get("filter", ":filter", use: getList)
        tokenGroup.get(":id", use: getInvoice)
        tokenGroup.get("pdf", ":reference", use: pdf)
        tokenGroup.patch("delays", ":id", use: checkDelays)
        tokenGroup.patch("remainder", ":id", use: sendRemainder)
        tokenGroup.patch("last", ":id", use: sendLastDayRemainder)
    }
    
    // MARK: Routes functions    
    /// Getting new invoice reference
    private func getInvoiceReference(req: Request) async throws -> Response {
        let invoices = try await Invoice.query(on: req.db).sort(\.$reference).all()
        
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
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode("F-\(date)-\(number)")))
    }
    
    /// Create invoice
    private func create(req: Request) async throws -> Response {
        let newInvoice = try req.content.decode(Invoice.Create.self)
        
        try await Invoice(reference: newInvoice.reference,
                          object: newInvoice.object,
                          totalServices: newInvoice.totalServices,
                          totalMaterials: newInvoice.totalMaterials,
                          totalDivers: newInvoice.totalDivers,
                          total: newInvoice.total,
                          grandTotal: newInvoice.grandTotal,
                          status: newInvoice.status,
                          limitPayementDate: newInvoice.limitPayementDate,
                          clientID: newInvoice.clientID,
                          facturationDate: Date(),
                          comment: newInvoice.comment,
                          maxInterests: newInvoice.maxInterests,
                          limitMaxInterests: newInvoice.limitMaximumInterests)
        .save(on: req.db)
        
        let invoice = try await Invoice.query(on: req.db)
            .filter(\.$reference == newInvoice.reference)
            .first()
        
        if let _ = try await InternalReference.query(on: req.db).filter(\.$ref == newInvoice.internalReference).first() {
            try await InternalReference.query(on: req.db)
                .set(\.$invoice.$id, to: invoice?.requireID())
                .filter(\.$ref == newInvoice.internalReference)
                .update()
        } else {
            try await InternalReference(ref: newInvoice.internalReference, invoiceID: invoice?.requireID()).save(on: req.db)
        }
        
        guard let invoice = invoice, let invoiceId = invoice.id else {
            throw Abort(.internalServerError)
        }
        
        for product in newInvoice.products {
            try await ProductInvoice(quantity: product.quantity, productID: product.productID, invoiceID: invoiceId).save(on: req.db)
        }
        
        return GlobalFunctions.shared.formatResponse(status: .created, body: .init(data: try JSONEncoder().encode("\(invoice.reference) is created!")))
    }
    
    /// Update invoice
    private func update(req: Request) async throws -> Response {
        let updatedInvoice = try req.content.decode(Invoice.Update.self)
        
        guard let invoice = try await Invoice.find(updatedInvoice.id, on: req.db), !invoice.isArchive else {
            throw Abort(.notAcceptable)
        }
        
        try await Invoice.query(on: req.db)
            .set(\.$object, to: updatedInvoice.object)
            .set(\.$totalServices, to: updatedInvoice.totalServices)
            .set(\.$totalMaterials, to: updatedInvoice.totalMaterials)
            .set(\.$totalDivers, to: updatedInvoice.totalDivers)
            .set(\.$total, to: updatedInvoice.total)
            .set(\.$grandTotal, to: updatedInvoice.grandTotal)
            .set(\.$status, to: updatedInvoice.status)
            .set(\.$creation, to: updatedInvoice.creationDate)
            .set(\.$payment.$id, to: updatedInvoice.paymentID)
            .set(\.$limitPayementDate, to: updatedInvoice.limitPayementDate ?? Date().addingTimeInterval(2592000))
            .set(\.$facturationDate, to: updatedInvoice.facturationDate)
            .set(\.$comment, to: updatedInvoice.comment)
            .set(\.$maxInterests, to: updatedInvoice.maxInterests)
            .set(\.$limitMaxInterests, to: updatedInvoice.limitMaximumInterests)
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
                        .set(\.$reduction, to: product.reduction)
                        .filter(\.$product.$id == product.productID)
                        .filter(\.$invoice.$id == updatedInvoice.id)
                        .update()
                } else {
                    try await ProductInvoice(quantity: product.quantity,
                                             reduction: product.reduction,
                                             productID: product.productID,
                                             invoiceID: updatedInvoice.id).save(on: req.db)
                }
            }
        }
        
        try await InternalReference.query(on: req.db)
            .set(\.$ref, to: updatedInvoice.internalReference)
            .filter(\.$invoice.$id == updatedInvoice.id)
            .update()
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Setting is payed
    private func isPaied(req: Request) async throws -> Response {
        guard let paiedInvoice = req.parameters.get("id", as: UUID.self) else { throw Abort(.notAcceptable) }
        
        try await Invoice.query(on: req.db)
            .set(\.$status, to: .payed)
            .set(\.$isArchive, to: true)
            .filter(\.$id == paiedInvoice)
            .update()
        
        if let invoice = try await Invoice.find(paiedInvoice, on: req.db), invoice.isArchive == true {
            let date = Date()
            let yearDateFormatter = DateFormatter()
            let monthDateFormatter = DateFormatter()
            yearDateFormatter.dateFormat = "yyyy"
            monthDateFormatter.dateFormat = "MM"
            
            guard let year = Int(yearDateFormatter.string(from: date)),
                  let month = Int(monthDateFormatter.string(from: date)) else {
                throw Abort(.internalServerError)
            }
            
            try await addToYearRevenue(year: year,
                                       totalServices: invoice.totalServices,
                                       totalMaterial: invoice.totalMaterials,
                                       totalDivers: invoice.totalDivers,
                                       grandTotal: invoice.total,
                                       in: req)
            try await addToMonthRevenue(month: month,
                                        year: year,
                                        totalServices: invoice.totalServices,
                                        totalMaterial: invoice.totalMaterials,
                                        totalDivers: invoice.totalDivers,
                                        grandTotal: invoice.total,
                                        in: req)
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Getting invoice list
    private func getList(req: Request) async throws -> Response {
        let filter = req.parameters.get("filter", as: Int.self)
        let invoices: [Invoice.Summary]
        
        if let filter = filter {
            invoices = formatInvoiceSummaray(try await Invoice.query(on: req.db).with(\.$client).sort(\.$facturationDate).range(..<filter).all())
        } else {
            invoices = formatInvoiceSummaray(try await Invoice.query(on: req.db).with(\.$client).sort(\.$reference).all())
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(invoices)))
    }
    
    /// Getting invoice
    private func getInvoice(req: Request) async throws -> Response {
        let id = req.parameters.get("id", as: UUID.self)
        let serverIP = Environment.get("SERVER_HOSTNAME") ?? "127.0.0.1"
        let serverPort = Environment.get("SERVER_PORT").flatMap(Int.init(_:)) ?? 8080
        
        guard let id = id,
              let invoice = try await Invoice.find(id, on: req.db),
              let client = try await Client.find(invoice.$client.id, on: req.db),
              let internalRef = try await InternalReference.query(on: req.db).filter(\.$invoice.$id == invoice.requireID()).first()?.ref else {
            throw Abort(.notFound)
        }
        
        let productsInvoice = try await ProductInvoice.query(on: req.db).filter(\.$invoice.$id == id).all()
        var products: [Product.Informations] = []
        
        for productInvoice in productsInvoice {
            guard let product = try await Product.find(productInvoice.$product.id, on: req.db), let productId = product.id else { throw Abort(.notAcceptable) }
            products.append(Product.Informations(id: productId,
                                                 quantity: productInvoice.quantity,
                                                 reduction: productInvoice.reduction,
                                                 title: product.title,
                                                 unity: product.unity,
                                                 domain: product.domain,
                                                 productCategory: product.productCategory,
                                                 price: product.price))
        }
        
        let payment: PayementMethod?
        
        if let paymentID = invoice.$payment.id {
            let paymentResponse = try await req.client.get("http://\(serverIP):\(serverPort)/payment/\(paymentID)", headers: req.headers)
            
            guard var paymentData = paymentResponse.body, let data = paymentData.readData(length: paymentData.readableBytes) else {
                throw Abort(.internalServerError)
            }
            
            payment = try JSONDecoder().decode(PayementMethod.self, from: data)
        } else {
            payment = nil
        }
        
        let invoiceInformations = Invoice.Informations(id: id,
                                                       reference: invoice.reference,
                                                       internalReference: internalRef,
                                                       object: invoice.object,
                                                       totalServices: invoice.totalServices,
                                                       totalMaterials: invoice.totalMaterials,
                                                       totalDivers: invoice.totalDivers,
                                                       total: invoice.total,
                                                       grandTotal: invoice.grandTotal,
                                                       status: invoice.status,
                                                       limitPayementDate: invoice.limitPayementDate,
                                                       facturationDate: invoice.facturationDate,
                                                       delayDays: invoice.delayDays,
                                                       totalDelay: invoice.totalDelay,
                                                       creationDate: invoice.creation,
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
                                                       products: products,
                                                       payment: payment,
                                                       isArchive: invoice.isArchive,
                                                       comment: invoice.comment,
                                                       limitMaximumInterests: invoice.limitMaxInterests,
                                                       maxInterests: invoice.maxInterests)
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(invoiceInformations)))
    }
    
    /// Export to PDF
    private func pdf(req: Request) async throws -> Response {
        let document = Document(margins: 15)
        
        let reference = req.parameters.get("reference")
        let serverIP = Environment.get("SERVER_HOSTNAME") ?? "127.0.0.1"
        let serverPort = Environment.get("SERVER_PORT").flatMap(Int.init(_:)) ?? 8080
        
        guard let reference = reference,
              let invoice = try await Invoice.query(on: req.db).filter(\.$reference == reference).first(),
              let id = invoice.id,
              let client = try await Client.find(invoice.$client.id, on: req.db),
              let internalRef = try await InternalReference.query(on: req.db).filter(\.$invoice.$id == id).first()?.ref else {
            throw Abort(.notFound)
        }
        
        let productsInvoice = try await ProductInvoice.query(on: req.db).filter(\.$invoice.$id == id).all()
        var products: [Product.Informations] = []
        
        for productInvoice in productsInvoice {
            guard let product = try await Product.find(productInvoice.$product.id, on: req.db), let productId = product.id else { throw Abort(.notAcceptable) }
            products.append(Product.Informations(id: productId,
                                                 quantity: productInvoice.quantity,
                                                 reduction: productInvoice.reduction,
                                                 title: product.title,
                                                 unity: product.unity,
                                                 domain: product.domain,
                                                 productCategory: product.productCategory,
                                                 price: product.price))
        }
        
        let address = try await addressController.getAddressFromId(client.$address.id, for: req)
        
        let payment: PayementMethod?
        
        if let paymentID = invoice.$payment.id {
            let paymentResponse = try await req.client.get("http://\(serverIP):\(serverPort)/payment/\(paymentID)", headers: req.headers)
            
            guard var paymentData = paymentResponse.body, let data = paymentData.readData(length: paymentData.readableBytes) else {
                throw Abort(.internalServerError)
            }
            
            payment = try JSONDecoder().decode(PayementMethod.self, from: data)
        } else {
            payment = nil
        }
        
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
        
        var hasComment = false
        if let comment = invoice.comment {
            hasComment = !comment.isEmpty
        }
        
        var interestMessage = ""
        
        if let maxInterests = invoice.maxInterests,
           let maxLimitInterests = invoice.limitMaxInterests,
           maxInterests > 0,
           maxLimitInterests >= Date() {
            if invoice.totalDelay < maxInterests {
                interestMessage = "De comme un accord, les intérêts sont plafonnés à \(maxInterests.twoDigitPrecision) € pour un payement avant le \(maxLimitInterests.dateOnly)"
            } else {
                interestMessage = "\(invoice.totalDelay.twoDigitPrecision) € (Plafonné à \(maxInterests.twoDigitPrecision) € pour un payement avant le \(maxLimitInterests.dateOnly))"
            }
        } else {
            interestMessage = "((\(invoice.total.twoDigitPrecision) * 3 * 0,0077 * \(invoice.delayDays)) / 365) + 40"
        }
        
        let materialsProducts = getPdfProductList(products, for: .material)
        let servicesProducts = getPdfProductList(products, for: .service)
        let diversProducts = getPdfProductList(products, for: .divers)
        
        let page = req.view.render("invoice", Invoice.PDF(creationDate: Date().dateOnly,
                                                          reference: invoice.reference,
                                                          clientName: clientName,
                                                          clientAddress: "\(address.streetNumber) \(address.roadName)",
                                                          clientCity: "\(address.zipCode), \(address.city)",
                                                          clientCountry: address.country,
                                                          internalReference: internalRef,
                                                          object: invoice.object,
                                                          paymentTitle: payment?.title ?? "",
                                                          iban: payment?.iban ?? "",
                                                          bic: payment?.bic ?? "",
                                                          total: invoice.total.twoDigitPrecision,
                                                          grandTotal: invoice.grandTotal.twoDigitPrecision,
                                                          materialsProducts: materialsProducts,
                                                          servicesProducts: servicesProducts,
                                                          diversProducts: diversProducts,
                                                          totalServices: invoice.totalServices.twoDigitPrecision,
                                                          totalMaterials: invoice.totalMaterials.twoDigitPrecision,
                                                          totalDivers: invoice.totalDivers.twoDigitPrecision,
                                                          limitDate: invoice.limitPayementDate.dateOnly,
                                                          facturationDate: invoice.facturationDate.dateOnly,
                                                          delayDays: "\(invoice.delayDays)",
                                                          totalDelay: "\(invoice.totalDelay.twoDigitPrecision)",
                                                          tva: client.tva ?? "",
                                                          siret: client.siret ?? "",
                                                          hasTva: client.tva != nil,
                                                          hasSiret: client.siret != nil,
                                                          hasADelay: invoice.totalDelay > 0.0,
                                                          hasComment: hasComment,
                                                          comment: invoice.comment ?? "",
                                                          interestMessage: interestMessage))
        
        let pages = try [page]
            .flatten(on: req.eventLoop)
            .map({ views in
                views.map { view in
                    Page(view.data)
                }
            }).wait()
        
        document.pages = pages
        let pdf = try await document.generatePDF(on: req.application.threadPool, eventLoop: req.eventLoop, title: invoice.reference)
        
        return Response(status: .ok, headers: HTTPHeaders([("Content-Type", "application/pdf")]), body: .init(data: pdf))
    }
    
    /// Send invoice remainder
    private func sendRemainder(_ req: Request) async throws -> Response {
        let invoiceId = req.parameters.get("id", as: UUID.self)
        
        guard let invoiceId = invoiceId,
              let invoice = try await Invoice.find(invoiceId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if invoice.status == .sent {
            let limitDate = Calendar.current.date(byAdding: .day, value: -7, to: invoice.limitPayementDate)
            let today = Date()
            
            if limitDate?.dateOnly == today.dateOnly {
                try await sendRemainderEmail(for: invoiceId, on: req, withRemainder: .sevenDays)
            }
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Send invoice last day remainder
    private func sendLastDayRemainder(_ req: Request) async throws -> Response {
        let invoiceId = req.parameters.get("id", as: UUID.self)
        guard let invoiceId = invoiceId,
              let invoice = try await Invoice.find(invoiceId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if invoice.status == .sent {
            let limitDate = invoice.limitPayementDate
            let today = Date()
            
            if limitDate.dateOnly == today.dateOnly {
                try await sendRemainderEmail(for: invoiceId, on: req, withRemainder: .lastDay)
            }
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Check if the invoice is delayed
    private func checkDelays(_ req: Request) async throws -> Response {
        let invoiceId = req.parameters.get("id", as: UUID.self)
        
        guard let invoiceId = invoiceId,
              let invoice = try await Invoice.find(invoiceId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if invoice.status == .sent || invoice.status == .overdue {
            let today = Date()
            let limitDate = invoice.limitPayementDate
            
            if limitDate < today {
                let calendar = Calendar.current
                let delay = calendar.numberOfDaysBetween(limitDate, and: today)
                
                let interestsRate = 3 * 0.0077
                let total = invoice.totalMaterials + invoice.totalDivers + invoice.totalServices
                var interests = ((total * interestsRate * Double(delay)) / 365.0) + 40.0
                
                if let maxInterest = invoice.maxInterests,
                   let maxLimitInterests = invoice.limitMaxInterests,
                   maxInterest < interests,
                   maxLimitInterests >= today {
                    interests = maxInterest
                }
                
                try await Invoice.query(on: req.db)
                    .set(\.$totalDelay, to: interests)
                    .set(\.$delayDays, to: delay)
                    .set(\.$grandTotal, to: invoice.total + interests)
                    .set(\.$status, to: .overdue)
                    .filter(\.$id == invoiceId)
                    .update()
                
                try await sendDelayEmail(for: invoiceId, on: req)
            }
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    // MARK: Utilities functions
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
                                                      grandTotal: invoice.total,
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
                .set(\.$totalDivers, to: (record.totalDivers + totalDivers))
                .set(\.$grandTotal, to: (record.grandTotal + grandTotal))
                .filter(\.$year == year)
                .update()
        } else {
            try await YearRevenue(year: year,
                                  totalServices: totalServices,
                                  totalMaterials: totalMaterial,
                                  totalDivers: totalDivers,
                                  grandTotal: grandTotal).save(on: req.db)
        }
    }
    
    /// Adding invoice to month revenue
    private func addToMonthRevenue(month: Int, year: Int, totalServices: Double, totalMaterial: Double, totalDivers: Double, grandTotal: Double, in req: Request) async throws {
        if let record = try await MonthRevenue.query(on: req.db).filter(\.$year == year).filter(\.$month == month).first() {
            try await MonthRevenue.query(on: req.db)
                .set(\.$totalServices, to: (record.totalServices + totalServices))
                .set(\.$totalMaterials, to: (record.totalMaterials + totalMaterial))
                .set(\.$totalDivers, to: (record.totalDivers + totalDivers))
                .set(\.$grandTotal, to: (record.grandTotal + grandTotal))
                .filter(\.$year == year)
                .filter(\.$month == month)
                .update()
        } else {
            try await MonthRevenue(month: month,
                                   year: year,
                                   totalServices: totalServices,
                                   totalMaterials: totalMaterial,
                                   totalDivers: totalDivers,
                                   grandTotal: grandTotal).save(on: req.db)
        }
    }
    
    /// Getting product list for PDF
    private func getPdfProductList(_ products: [Product.Informations], for category: ProductCategory) -> [[String]] {
        return (
            products
                .filter({$0.productCategory == category})
                .map({ return [$0.title,
                               $0.quantity.twoDigitPrecision,
                               "\($0.price.twoDigitPrecision) \($0.unity ?? "")",
                               "\($0.reduction.twoDigitPrecision) % (\(($0.price * $0.quantity * ($0.reduction/100)).twoDigitPrecision) €)",
                               "\(($0.price * $0.quantity * ((100-$0.reduction)/100)).twoDigitPrecision) €"]})
        )
    }
    
    /// Send delay invoice email
    private func sendDelayEmail(for invoiceId: UUID, on req: Request) async throws {
        guard let invoice = try await Invoice.find(invoiceId, on: req.db),
              let client = try await Client.find(invoice.$client.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let name = getNameForEmail(of: client)
        var interestMessage = ""
        
        if let maxInterests = invoice.maxInterests,
           let maxLimitInterests = invoice.limitMaxInterests,
           maxInterests > 0,
           maxLimitInterests >= Date() {
            interestMessage = "Nous vous rappelons qu'un accord vous octroyant un plafond de <strong>\(maxInterests.twoDigitPrecision) €</strong> d'intérêt est toujours valable. Celui-ci le restera jusqu'au <strong>\(maxLimitInterests.dateOnly)</strong>. Dès le lendemain de cette date, les intérêts seront recalculés en fonction des conditions générales en prenant comme nombre de jours de retard, la date limite de payement inscrite sur la facture."
        } else {
            interestMessage = """
                            Calcul des intétêts:<br/>
                            ((total TTC * 3 * taux légal * nombre de jours de retard)/365) + frais de recouvrement = intérêts<br/>
                            ((\(invoice.total.twoDigitPrecision) * 3 * 0,0077 * \(invoice.delayDays)) / 365) + 40 = \(invoice.totalDelay.twoDigitPrecision) €
                            """
        }
        
        let message = """
                    Sauf temps de traitement des banques, vous avez une facture non réglée (<strong>\(invoice.reference)</strong>) d'un montant de <strong>\(invoice.total.twoDigitPrecision) € </strong>.<br/>
                    La date d'échéance étant le <strong>\(invoice.limitPayementDate.dateOnly)</strong>, vous êtes dorénavant en retard de payement. De ce fait, vous devez regler, en plus du montant de votre facture, des intérêts qui s'élèvent à ce jour à <strong>\(invoice.totalDelay.twoDigitPrecision) €</strong>.<br/>
                    <br/>
                    \(interestMessage)<br/>
                    <br/>
                    Le montant total à payer à ce jour est de: <strong>\(invoice.grandTotal.twoDigitPrecision) €</strong>.<br/>
                    <br/>
                    Si le payement a déjà été effectué, merci d'envoyer une preuve de payement à contact@desyntic.com.<br/>
                    """
        
        try await GlobalFunctions.shared.sendEmail(for: invoice.id,
                                                   toName: name,
                                                   email: client.email,
                                                   withTitle: "[Retard] Règlement de votre facture \(invoice.reference)",
                                                   andMessage: message,
                                                   on: req)
    }
    
    /// Send remainder email
    private func sendRemainderEmail(for invoiceId: UUID, on req: Request, withRemainder type: RemainderType) async throws {
        guard let invoice = try await Invoice.find(invoiceId, on: req.db),
              let client = try await Client.find(invoice.$client.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let name = getNameForEmail(of: client)
        
        var remainderMessage = ""
        
        switch type {
        case .lastDay:
            remainderMessage = "Pour rappel, vous avez jusqu'à <strong>aujourd'hui</strong> pour réglé votre facture. A compté de demain, vous serez redevables d'intérêts."
        case .sevenDays:
            remainderMessage = "Pour rappel, vous avez jusqu'au <strong>\(invoice.limitPayementDate.dateOnly)</strong> pour régler votre facture."
        }
        
        let message = """
                    Sauf temps de traitement des banques, vous avez une facture non réglée (<strong>\(invoice.reference)</strong>) d'un montant de <strong>\(invoice.total.twoDigitPrecision) €</strong>.<br>
                    \(remainderMessage) <br>
                    <br>
                    Si le payement a déjà été effectué, merci d'envoyer une preuve de payement à contact@desyntic.com.
                    """
        
        try await GlobalFunctions.shared.sendEmail(for: invoice.id,
                                                   toName: name,
                                                   email: client.email,
                                                   withTitle: "[Rappel] Règlement de votre facture \(invoice.reference)",
                                                   andMessage: message,
                                                   on: req)
    }
    
    /// Getting name for email
    private func getNameForEmail(of client: Client) -> String {
        var name = ""
        
        if let lastname = client.lastname {
            name = "\(client.gender == .man ? "M." : client.gender == .woman ? "Mme." : "")\(lastname)"
        }
        
        if let company = client.company {
            if name.isEmpty {
                name = company
            } else {
                name.append(" (\(company))")
            }
        }
        
        if name.isEmpty {
            name = "Madame, Monsieur"
        }
        
        return name
    }
}

enum RemainderType {
    case sevenDays, lastDay
}
