//
//  ReservationController.swift
//  MigrateProject
//
//  Created by Apprenant 77 on 29/09/2026.
//

import Fluent
import Vapor
struct ReservationController: RouteCollection{
    func boot(routes: any RoutesBuilder) throws {
        let reservations = routes.grouped("reservations")
        reservations.get(use: index)
        
        reservations.group(":reservationID") { idPath in
            
        }
        
        reservations.post("participate",":reservationID", use: participate)
        reservations.delete("cancel",":reservationID", use: cancel)
        reservations.delete(":reservationID", use: delete)
        
    }
    
    
    //get all reservations
    func index(req :Request) async throws -> [Reservation]{
        return try await Reservation.query(on: req.db)
            .all()
    }
    
    
    //create reservation
    func participate(req: Request) async throws -> Reservation {
        
        guard let id = req.parameters.get("reservationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let reservation = try await Reservation.find(id, on: req.db) else { throw Abort(.notFound)}
        
        reservation.status = "valide"
        
        try await reservation.update(on: req.db)
        
        return reservation
    }
    
    
    //cancel reservation
    func cancel(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get(
        "reservationID",as: UUID.self)
        else {throw Abort(.badRequest)}
        guard let reservation = try await Reservation.find(
            id,on: req.db)
        else {throw Abort(.notFound)}
        reservation.status = "annule"
        try await reservation.update(on: req.db)
        return .noContent
    }
    
    
    
    //delete reservation
    func delete(req : Request) async throws -> HTTPStatus{
        guard let id = req.parameters.get("reservationID", as: UUID.self)
                else{throw Abort(.badRequest)}
        guard let reservation = try await Reservation.find(id, on: req.db)
                else{throw Abort(.notFound)}
        try await reservation.delete(on: req.db)
        return .noContent
    }
    
}
