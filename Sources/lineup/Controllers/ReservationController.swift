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
        var reservations = routes.grouped("reservations")
        reservations = reservations.grouped(JWTMiddleware())
        
        reservations.get(use: getAll)
        reservations.get(":id", use: getOneById)
        reservations.post("participate", use: participate)
        reservations.delete("cancel",":id", use: cancel)
    }
    
    
    //get all reservations
    func getAll(req :Request) async throws -> [ReservationDTO] {
        return try await Reservation
            .query(on: req.db)
            .with(\.$user)
            .with(\.$workshop)
            .all()
            .map({ $0.toReservationDTO() })
    }
    
    //get one reservation
    func getOneById(req :Request) async throws -> ReservationDTO {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let reservation = try await Reservation
            .query(on: req.db)
            .filter(\.$id == id)
            .with(\.$user)
            .with(\.$workshop)
            .first()
        else {
            throw Abort(.notFound)
        }
        
        return reservation.toReservationDTO()
    }
    
    
    //create reservation
    func participate(req: Request) async throws -> Response {
        var reservation = try req.content.decode(CreateReservationDTO.self)
            
        let payload = try req.auth.require(UserPayload.self)
        
        guard let userDB = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        reservation.userID = userDB.id
        
        let existingReservation = try await Reservation.query(on: req.db)
            .filter(\.$user.$id == reservation.userID!)
            .filter(\.$workshop.$id == reservation.workshopID)
            .first()
        
        if existingReservation != nil {
            return Response(status: .custom(code: 409, reasonPhrase: "Reservation already exist."))
        } else {
            let reservationModel = try reservation.toModel()
            try await reservationModel.save(on: req.db)
            return Response(status: .created)
        }
        
        
    }
    
    //cancel reservation
    func cancel(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let reservation = try await Reservation.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let payload = try req.auth.require(UserPayload.self)
        
        guard reservation.$user.id == payload.id else {
            throw Abort(.forbidden, reason: "Not authorized")
        }
        
                
        reservation.status = ReservationStatus.cancel.rawValue

        try await reservation.update(on: req.db)

        return .noContent
    }
    
}
