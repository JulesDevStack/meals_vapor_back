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
        reservations.get("available", use: getWorkshopsForUser)
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
    
    @Sendable
    func getWorkshopsForUser(req: Request) async throws -> [WorkshopWithUserReservationDTO] {
        let payload = try req.auth.require(UserPayload.self)

        let workshops = try await Workshop
            .query(on: req.db)
            .with(\.$reservations)
            .with(\.$category)
            .all()

        return try workshops.map { workshop in
            let userReservation = workshop.reservations.first { reservation in
                reservation.$user.id == payload.id
            }

            return WorkshopWithUserReservationDTO(
                workshopDTO: try workshop.toWorkshopDTO(),
                reservationDTO: try userReservation.map { reservation in
                    try reservation.toReservationInlineDTO()
                }
            )
        }
    }
    
    
    //create reservation
    func participate(req: Request) async throws -> Response {
        let reservation = try req.content.decode(CreateReservationDTO.self)
        let payload = try req.auth.require(UserPayload.self)
        try await req.application.reservationCoordinator.participate(
            userID: payload.id,
            workshopID: reservation.workshopID,
            on: req.db
        )
        return Response(status: .created)
    }
    
    //cancel reservation
    func cancel(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let payload = try req.auth.require(UserPayload.self)
        try await req.application.reservationCoordinator.cancel(id: id, userID: payload.id, on: req.db)

        return .noContent
    }
    
}
