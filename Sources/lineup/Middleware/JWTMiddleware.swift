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
        
        // Bypass authentication during unit testing if needed
        if request.application.environment == .testing {
            return next.respond(to: request)
        }
        
        //get token from https headers Authorization
        guard let token = request.headers.bearerAuthorization?.token else {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "missing token"))
        }
        
        //crée une instance d'un signer pour le hash
        let signer = JWTSigner.hs256(key: "MACLESUPERSECRETE")
        
        //crée un objet pour recuperer l'utilisateur
        let payload: UserPayload
        
        do {
            //essaye de recuperer l'utilisateur depuis le token
            payload = try signer.verify(token, as: UserPayload.self) //cast String(token)
        } catch {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "invalid token"))
        }
        
        //enregistre l'utilisateur trouvé dans la requette
        request.auth.login(payload)
        
        //passe a la fonction d'apres (controller)
        return next.respond(to: request)
    }
}
