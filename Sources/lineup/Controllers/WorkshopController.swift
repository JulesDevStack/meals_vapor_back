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
    
    
}
