//
//  String.swift
//  
//
//  Created by Kevin Bertrand on 24/11/2022.
//

import Fluent
import Foundation

extension String {
    var fieldKey: FieldKey {
        .string(self)
    }
}
