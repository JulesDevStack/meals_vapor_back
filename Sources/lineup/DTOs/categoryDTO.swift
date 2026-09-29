//
//  categoryDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor

struct categoryDTO: Content {
    var id: UUID
    var name: String
}
