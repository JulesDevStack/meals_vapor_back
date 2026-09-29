//
//  CreateUser.swift
//  vaporMediatheque
//
//  Created by apprenant102 on 29/09/2026.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema(User.schema)
            .id()
            .field(
                "name",
                .string,
                .required
            )
            .field(
                "password",
                .string,
                .required
            )
            .field(
                "email",
                .string,
                .required
            )
            .field(
                "roll",
                .string,
                .required
            )
            .field(
                "created_at",
                .datetime,
                .required
            )
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(User.schema)
            .delete()
    }
}
