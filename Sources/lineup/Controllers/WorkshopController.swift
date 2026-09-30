//
//  File.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//

import Fluent
import Vapor

struct WorkshopController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let path = routes.grouped("workshops")
        
        path.get("", use: index)
        path.post("", use: createWorkshop)
    }
    
    @Sendable
    func index(req: Request) async throws -> [WorkshopDTO] {
        let workshops = try await Workshop.query(on: req.db)
            .with(\.$category)
            .all()
        return try workshops.map({ try $0.toWorkshopDTO() })
    }
    
    func createWorkshop(req: Request) async throws -> Response {
        //VALIDER LES DONNEE ???
//        try CreateEventRequest.validate(content: req)
//        struct CreateEventRequest: Content, Validatable {
//        static func validations(_ validations: inout Validations) {
//        validations.add("title", as: String.self, is: !.empty)
        
        
        let workshop = try req.content.decode(CreateWorkshopDTO.self).toModel()
        try await workshop.save(on: req.db)
        let res = Response(status: .created)
        return res
    }
    
//    func getWorkshopWithReservation(req: Request) async throws -> WorkshopWithReservationDTO {
//        guard let id = req.parameters.get("id", as: UUID.self) else {
//            throw Abort(.badRequest, reason: "workshop id is required")
//        }
//        
//        guard let workshop = try await Workshop.find(id, on: req.db) else {
//            throw Abort(.notFound, reason: "workshop not found")
//        }
//        
//        guard let reservation = try await Reservation
//            .query(on: req.db)
//            .filter(<#T##filter: ModelFieldFilter<Reservation, Reservation>##ModelFieldFilter<Reservation, Reservation>#>)
//        
//        return try workshop.toWorkshopDTO()
//    }
    
    
}
