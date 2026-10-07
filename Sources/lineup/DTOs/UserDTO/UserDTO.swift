//
//  File.swift
//  lineup
//
//  Created by Jules Liegeois on 01/10/2026.
//

import Fluent
import Vapor
import JWT

struct UserDTO: Content {
    let id: UUID?
    let name: String
    let email: String
    let role: String
    let createdAt: Date
}

extension UserDTO {
    func toModel() -> User {
        return User(name: name, password: "default", email: email, role: "USER", createdAt: .now)
    }
}
