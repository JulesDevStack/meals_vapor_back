//
//  File.swift
//  lineup
//
//  Created by Jules Liegeois on 01/10/2026.
//

import Foundation
import Vapor
import JWT

struct UserPayload: JWTPayload, Authenticatable {
    var id: UUID
    var expiration: Date
    
    init(id: UUID) {
        self.id = id
        expiration = Date().addingTimeInterval(3600 * 24)
    }
    
    func verify(using signer: JWTSigner) throws {
        if expiration < Date() {
            throw JWTError.invalidJWK
        }
    }
}
