//
//  CreateReservation.swift
//
//
//  Created by apprenant102 on 29/09/2026.
//

import Fluent

struct CreateReservation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema(Reservation.schema)
            .id()
            .field(
                "fk_id_workshop",
                .uuid,
                .required,
                .references(
                    Workshop.schema,
                    "id"
                )
            )
            .field(
                "fk_id_user",
                .uuid,
                .required,
                .references(
                    User.schema,
                    "id"
                )
            )
            .field(
                "status",
                .string,
                .required
            )
            .unique(on: "fk_id_workshop", "fk_id_user")
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(Reservation.schema)
            .delete()
    }
}
