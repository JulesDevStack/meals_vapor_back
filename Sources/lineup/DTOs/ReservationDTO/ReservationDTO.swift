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

extension Reservation {
    func toReservationDTO() -> ReservationDTO {
        return ReservationDTO(id: self.id, userName: self.user.name, status: self.status)
    }
}
