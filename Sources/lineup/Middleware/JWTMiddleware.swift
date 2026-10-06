//
//  JWTMiddleware.swift
//  lineup
//
//  Created by Jules Liegeois on 01/10/2026.
//

import Vapor
import JWT

final class JWTMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        guard let token = request.headers.bearerAuthorization?.token else {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "missing token"))
        }
        
                
        let signer = JWTSigner.hs256(key: Environment.get("JWT_KEY")!)
        let payload: UserPayload
        
        do {
            payload = try signer.verify(token, as: UserPayload.self) //cast String(token)
        } catch {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "invalid token"))
        }
        
        request.auth.login(payload)
        
        return next.respond(to: request)
    }
}
