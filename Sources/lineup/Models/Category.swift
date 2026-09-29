//
//  Workshop.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//

import Fluent
import Vapor

final class Category: Model, @unchecked Sendable {
    static let schema = "categories"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Children(for: \.$category)
    var workshops: [Workshop]

    init() { }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
    
//    func toDTO() -> Category {
//        .init(
//            id: self.id,
//            name: self.name
//        )
//    }
}
