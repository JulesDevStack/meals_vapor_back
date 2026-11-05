//
//  ReservationDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor


struct ReservationDTO: Content {
    var id: UUID?
    var userName: String
    var status: String
}

struct ReservationInlineDTO: Content {
    var id: UUID?
    var status: String
}

extension Reservation {
    func toReservationInlineDTO() throws -> ReservationInlineDTO {
        return ReservationInlineDTO(
            id: try requireID(),
            status: self.status
        )
    }
    
    func toReservationDTO() -> ReservationDTO {
        return ReservationDTO(
            id: self.id,
            userName: self.user.name,
//            workshopName: self.workshop.name,
            status: self.status
        )
    }
    
    func toReservationWithWorkshopDTO() throws -> ReservationWithWorkshopDTO {
        return ReservationWithWorkshopDTO(
            reservationStatus: self.status,
            reservationId: try requireID(),
            workshopDTO: WorkshopDTO(
                id: try requireID(),
                name: self.workshop.name,
                startTime: self.workshop.startTime,
                endTime: self.workshop.endTime,
                maxCapacity: self.workshop.maxCapacity,
                totalSubscribers: self.workshop.totalSubscribers,
                description: self.workshop.description,
                categoryName: self.workshop.category.name,
                categoryID: try self.workshop.category.requireID(),
                availableSpot: self.workshop.maxCapacity - self.workshop.totalSubscribers
            )
        )
    }
}

struct ReservationWithWorkshopDTO: Content {
    var reservationStatus: String
    var reservationId: UUID
    var workshopDTO: WorkshopDTO
}
