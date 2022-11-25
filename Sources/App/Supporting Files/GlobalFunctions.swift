//
//  GlobalFunctions.swift
//  
//
//  Created by Kevin Bertrand on 24/11/2022.
//

import Fluent
import Foundation
import Vapor

class GlobalFunctions {
    static let shared = GlobalFunctions()
    
    /// Getting the connected user
    func getUserAuthFor(_ req: Request) throws -> Staff {
        return try req.auth.require(Staff.self)
    }
    
    /// Formating response
    func formatResponse(status: HTTPResponseStatus, body: Response.Body) -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        return .init(status: status, headers: headers, body: body)
    }
    
    /// Sending emails
    func sendEmail(for id: UUID?,
                   toName clientName: String,
                   email: String,
                   withTitle title: String,
                   andMessage message: String,
                   on request: Request) async throws {

        let serverIP = Environment.get("SERVER_HOSTNAME") ?? "127.0.0.1"
        let serverPort = Environment.get("SERVER_PORT").flatMap(Int.init(_:)) ?? 8080
        
        guard let invoice = try await Invoice.find(id, on: request.db),
              let apiKey = Environment.get("MAIL_KEY") else { throw Abort(.notFound) }
        
        let invoicePDF = try await request.client.get("http://\(serverIP):\(serverPort)/invoice/pdf/\(invoice.reference)", headers: request.headers)
        
        guard var pdf = invoicePDF.body, let pdfData = pdf.readData(length: pdf.readableBytes) else {
            throw Abort(.internalServerError)
        }
                
        let page = request.view.render("remainder", ["message": message, "name": clientName])
        guard let mail = try [page]
            .flatten(on: request.eventLoop)
            .map({ views in
                views.map { view in
                    Page(view.data)
                }
            }).wait().first?.content else { return }
        
        let data = EmailFormatting(sender: PersonEmailInfo(name: "Desyntic", email: "no-reply@desyntic.com"),
                                   to: [PersonEmailInfo(name: clientName, email: email)],
                                   bcc: [PersonEmailInfo(name: "Desyntic", email: "contact@desyntic.com")],
                                   subject: title,
                                   htmlContent: String(decoding: mail, as: UTF8.self),
                                   attachment: [.init(name: "\(invoice.reference).pdf", content: String(decoding: pdfData, as: UTF8.self))])

        let headers: HTTPHeaders = [
            "api-key": apiKey,
            "accept": "application/json",
            "content-type": "application/json"
        ]
        
        _ = try await request.client.post("https://api.sendinblue.com/v3/smtp/email", headers: headers) { req in
            try req.content.encode(data)
        }
    }
}

struct EmailFormatting: Codable, Content {
    let sender: PersonEmailInfo
    let to: [PersonEmailInfo]
    let bcc: [PersonEmailInfo]
    let subject: String
    let htmlContent: String
    let attachment: [AttachementFiles]
}

struct PersonEmailInfo: Codable {
    let name: String
    let email: String
}

struct AttachementFiles: Codable {
    let name: String
    let content: String
}
