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
    var availableSpot: Int {
        maxCapacity - totalSubscribers
    }
}

struct WorkshopWithReservationDTO: Content {
    var workshopDTO: WorkshopDTO
    var reservations: [ReservationDTO]
}

