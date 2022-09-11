//
//  UUID.swift
//  
//
//  Created by Kevin Bertrand on 11/09/2022.
//

import Foundation

extension UUID {
    var empty: UUID {
        return UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}
