//
//  File.swift
//  
//
//  Created by Kevin Bertrand on 20/09/2022.
//

import Foundation
import Queues
import Vapor

struct InvoiceStatusJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        print("ok")
    }
}
