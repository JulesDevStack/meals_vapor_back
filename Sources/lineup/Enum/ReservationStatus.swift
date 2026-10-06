//
//  ReservationStatus.swift
//  lineup
//
//  Created by Jules Liegeois on 29/09/2026.
//

import Foundation

enum ReservationStatus: String, CaseIterable {
    case validate = "validée"
    case waiting = "en attente"
    case cancel = "annulée"
}
