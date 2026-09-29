//
//  Workshop.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//

import Fluent
import Vapor

final class Workshop: Model, @unchecked Sendable {
    static let schema = "workshops"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "start_time")
    var startTime: Date
    
    @Field(key: "end_time")
    var endTime: Date
    
    @Field(key: "max_capacity")
    var maxCapacity: Int
    
    @Field(key: "total_subscribers")
    var totalSubscribers: Int
    
    @Field(key: "description")
    var description: String
    
    @Parent(key: "fk_id_category")
    var category: Category
    
    init() {}
    
    init(id: UUID? = nil, name: String, startTime: Date, endTime: Date, maxCapacity: Int, totalSubscribers: Int, description: String) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.maxCapacity = maxCapacity
        self.totalSubscribers = totalSubscribers
        self.description = description
    }

    init(id: UUID? = nil, name: String, startTime: Date, endTime: Date, maxCapacity: Int, totalSubscribers: Int, description: String, category: Category) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.maxCapacity = maxCapacity
        self.totalSubscribers = totalSubscribers
        self.description = description
        self.category = category
    }
    
}
