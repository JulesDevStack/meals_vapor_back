//
//  CreateWorkshopDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor

struct WorkshopDTO: Content {
    var id: UUID
    var name: String
    var startTime: Date
    var endTime: Date
    var maxCapacity: Int
    var totalSubscribers: Int
    var description: String
    var categoryName: String
    var availableSpot: Int
}

extension Workshop {
    func toWorkshopDTO() throws -> WorkshopDTO {
        return WorkshopDTO(
            id: try requireID(),
            name: self.name,
            startTime: self.startTime,
            endTime: self.endTime,
            maxCapacity: self.maxCapacity,
            totalSubscribers: self.totalSubscribers,
            description: self.description,
            categoryName: self.category.name,
            availableSpot: self.maxCapacity - self.totalSubscribers
        )
    }
    
    func toWorkshopWithReservationDTO() throws -> WorkshopWithReservationDTO {
        return WorkshopWithReservationDTO(
            workshopDTO: WorkshopDTO(
                id: try requireID(),
                name: self.name,
                startTime: self.startTime,
                endTime: self.endTime,
                maxCapacity: self.maxCapacity,
                totalSubscribers: self.totalSubscribers,
                description: self.description,
                categoryName: self.category.name,
                availableSpot: self.maxCapacity - self.totalSubscribers
            ),
            reservations: [
                
            ]
        )
    }
}


struct WorkshopWithReservationDTO: Content {
    var workshopDTO: WorkshopDTO
    var reservations: [ReservationDTO]
}

