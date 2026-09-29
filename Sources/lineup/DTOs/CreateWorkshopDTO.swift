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
    var totalSubscribers: Int  //TODO: supprimer car calculer ds le backend
    var description: String
    var categoryID: UUID
    
    func toModel() -> Workshop {
        let workshop = Workshop(
            name: self.name,
            startTime: self.startTime,
            endTime: self.endTime,
            maxCapacity: self.maxCapacity,
            totalSubscribers: self.totalSubscribers,
            description: self.description
        )
    
        workshop.$category.id = self.categoryID
        return workshop
    }
}

typealias UpdateWorkshopDTO = CreateWorkshopDTO
