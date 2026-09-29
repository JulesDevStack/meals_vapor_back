//
//  CreateWorkshopDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor

struct workshopDTO: Content {
    var id: UUID
    var name: String
    var startTime: Date
    var endTime: Date
    var maxCapacity: Int
    var totalSubscribers: Int
    var description: String
    var categoryID: UUID
}
