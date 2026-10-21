//
//  CreateReservationDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor

struct CreateReservationDTO: Content {
    var workshopID: UUID
    var userID: UUID?
    
    func toModel() throws -> Reservation {
        guard userID != nil else { throw Abort(.badRequest, reason: "Need user authentification")}
        
        let reservation = Reservation(
            status: ReservationStatus.validate.rawValue,
        )
    
        reservation.$workshop.id = self.workshopID
        reservation.$user.id = self.userID!
        
        return reservation
    }
}
