//
//  CreateWorkshopDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor

struct CreateWorkshopDTO: Content {
    var name: String
    var startTime: Date
    var endTime: Date
    var maxCapacity: Int
    var description: String
    var categoryID: UUID
    
    func toModel() -> Workshop {
        let workshop = Workshop(
            name: self.name,
            startTime: self.startTime,
            endTime: self.endTime,
            maxCapacity: self.maxCapacity,
            totalSubscribers: 0,
            description: self.description,
            categoryID: self.categoryID
        )
    
//        workshop.$category.id = self.categoryID
        return workshop
    }
}

typealias UpdateWorkshopDTO = CreateWorkshopDTO
