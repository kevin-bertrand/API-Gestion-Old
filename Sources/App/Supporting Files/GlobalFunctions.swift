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
    func sendEmail(toName clientName: String, email: String, withTitle title: String, andMessage message: String, on request: Request) async throws {
        guard let apiKey = Environment.get("MAIL_KEY") else { return }
        
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
                                   htmlContent: String(decoding: mail, as: UTF8.self))
        print(data)
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
}

struct PersonEmailInfo: Codable {
    let name: String
    let email: String
}
