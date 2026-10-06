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

        path.get(":id", use: getWorkshopWithReservation)
        
    }
    
    @Sendable
    func index(req: Request) async throws -> [WorkshopDTO] {
        let workshops = try await Workshop.query(on: req.db)
            .with(\.$category)
            .all()
        return try workshops.map({ try $0.toWorkshopDTO() })
    }
    
    @Sendable
    func getWorkshop(req: Request) async throws -> WorkshopDTO {
        
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
                
        guard let workshops = try await Workshop.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$category)
            .first()
        else {
            throw Abort(.notFound)
        }
        
        return try workshops.toWorkshopDTO()
    }
    
    @Sendable
    func getWorkshopWithReservation(req: Request) async throws -> WorkshopWithReservationDTO {
        
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let workshops = try await Workshop.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$reservations, { re in
                re.with(\.$user)
            })
            .with(\.$category)
            .first() else {
            throw Abort(.notFound)
        }
        
        return try workshops.toWorkshopWithReservationDTO()
    }
    
    func createWorkshop(req: Request) async throws -> Response {
        try CreateWorkshopDTO.validate(content: req)
        
        var workshop = try req.content.decode(CreateWorkshopDTO.self)
        
        guard workshop.startTime < workshop.endTime else {
            throw Abort(.badRequest, reason: "endTime must be greater than startTime")
        }
        
        guard try await Category.find(workshop.categoryID, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Category not found.")
        }
        
        let workshopModel = workshop.toModel()
        
        try await workshopModel.save(on: req.db)
        let res = Response(status: .created)
        return res
    }
}

