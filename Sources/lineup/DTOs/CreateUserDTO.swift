//
//  File.swift
//  lineup
//
//  Created by Jules Liegeois on 01/10/2026.
//

import Vapor

struct CreateUserDTO: Content {
    let name: String
    let email: String
    var password: String
}

extension CreateUserDTO {
    func toModel() -> User {
        return User(id: nil, name: name, password: password, email: email, role: "USER", createdAt: Date())
    }
}
