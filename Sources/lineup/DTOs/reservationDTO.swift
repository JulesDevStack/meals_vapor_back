//
//  reservationDTO.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//
import Fluent
import Vapor

struct reservationDTO: Content {
    var id: UUID
    var workshopID: UUID
    var userID: UUID
    var status: String
}
