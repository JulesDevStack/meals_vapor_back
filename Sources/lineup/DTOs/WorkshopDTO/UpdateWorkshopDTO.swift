//
//  UpdateWorkshopDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor

struct UpdateWorkshopDTO: Content, Validatable {
    var name: String
    var startTime: Date
    var endTime: Date
    var maxCapacity: Int
    var totalSubscribers: Int
    var description: String
    var categoryID: UUID
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("startTime", as: Date.self, is: .valid)
        validations.add("endTime", as: Date.self, is: .valid)
        validations.add("maxCapacity", as: Int.self, is: .range(1...Int.max))
        validations.add("totalSubscribers", as: Int.self, is: .range(1...Int.max))
        validations.add("description", as: String.self, is: .count(5...Int.max))
        validations.add("categoryID", as: UUID.self, is: .valid)
    }
    
    func toModel() -> Workshop {
        let workshop = Workshop(
            name: self.name,
            startTime: self.startTime,
            endTime: self.endTime,
            maxCapacity: self.maxCapacity,
            totalSubscribers: self.totalSubscribers,
            description: self.description,
            categoryID: self.categoryID
        )
    
        return workshop
    }
    
    func customValidation(db: any Database) async throws {
        guard self.startTime < self.endTime else {
            throw Abort(.badRequest, reason: "endTime must be greater than startTime")
        }
        guard try await Category.find(self.categoryID, on: db) != nil else {
            throw Abort(.notFound, reason: "Category not found.")
        }
    }
}

