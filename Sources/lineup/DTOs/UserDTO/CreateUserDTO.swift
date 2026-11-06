//
//  File.swift
//  lineup
//
//  Created by Jules Liegeois on 01/10/2026.
//

import Vapor

struct CreateUserDTO: Content, Validatable {
    let name: String
    let email: String
    var password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("name", as: String.self, is: .count(3...Int.max))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(5...64))
    }
}

extension CreateUserDTO {
    func toModel() -> User {
        return User(id: nil, name: name, password: password, email: email, role: "user", createdAt: Date())
    }
}
