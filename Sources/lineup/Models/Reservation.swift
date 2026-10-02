//
//  Reservation.swift
//  MigrateProject
//
//  Created by Apprenant 77 on 29/09/2026.
//

import Vapor

import Fluent
final class Reservation: Model, Content, @unchecked Sendable {
    static let schema: String = "reservations"
    
    @ID(key: .id)
    var id : UUID?
    
    @Parent(key: "fk_id_workshop")
    var workshop : Workshop
    
    @Parent(key: "fk_id_user")
    var user : User
    
    @Field(key: "status")
    var status : String
    
    init() {
        
    }
    
    init(id: UUID? = nil, status: String) {
        self.id = id
        self.status = status
    }
    
    init(id: UUID? = nil, workshop: UUID, user: UUID, status: String) {
        self.id = id
        self.$workshop.id = workshop
        self.$user.id = user
        self.status = status
    }
  
}
