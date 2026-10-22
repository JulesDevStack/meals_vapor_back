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

        path.group(":id") { pathId in
            pathId.get(use: getWorkshopWithReservation)
            pathId.put(use: editWorkshop)
        }
        
        path.get("cate", use: catIndex)
        
        path.grouped(JWTMiddleware())
            .get("reservations", use: getReservedWorkshopFromUser)
    }
    
    @Sendable
    func catIndex(req :Request) async throws -> [CategoryDTO] {
        return try await Category
            .query(on: req.db)
            .all()
            .map({ try $0.toDTO() })
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
    
    @Sendable
    //get all reservations from one user id
    func getReservedWorkshopFromUser(req: Request) async throws -> [WorkshopDTO] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let userDB = try await User
            .query(on: req.db)
            .filter(\.$id == payload.id)
            .with(\.$reservations, { re in
                re.with(\.$workshop, { wo in
                    wo.with(\.$category)
                })
            })
                .first()
                else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let workshops = try userDB
            .reservations
            .sorted(by: {$0.workshop.startTime < $1.workshop.startTime})
            .map { try $0.workshop.toWorkshopDTO() };
        
        return workshops
    }
    
    @Sendable
    func createWorkshop(req: Request) async throws -> Response {
        try CreateWorkshopDTO.validate(content: req)
        
        let workshop = try req.content.decode(CreateWorkshopDTO.self)
        
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
    
    @Sendable
    func editWorkshop(req: Request) async throws -> WorkshopDTO {
        let id = try req.parameters.require("id", as: UUID.self)
        
        try UpdateWorkshopDTO.validate(content: req)
        
        var updatedWorkshop = try req.content.decode(UpdateWorkshopDTO.self)
        try await updatedWorkshop.customValidation(db: req.db)
        
        guard let workshopModel = try await Workshop
            .query(on: req.db)
            .filter(\.$id == id)
            .with(\.$category)
            .with(\.$reservations)
            .first()
        else {
            throw Abort(.notFound, reason: "Workshop not found.")
        }
        
        updatedWorkshop.totalSubscribers = updatedWorkshop.maxCapacity - workshopModel.reservations.count
        
        workshopModel.apply(updatedWorkshop: updatedWorkshop)
        
        try await workshopModel.update(on: req.db)
        
        return try workshopModel.toWorkshopDTO()
    }
}

