//
//  File.swift
//  lineup
//
//  Created by Jules Liegeois on 01/10/2026.
//

import Vapor

struct LoginRequestDTO: Content {
    let email: String
    let password: String
}
