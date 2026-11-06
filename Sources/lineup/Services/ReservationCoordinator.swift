import Fluent
import Vapor

actor ReservationCoordinator {
    private var busy = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    private func enter() async {
        if busy {
            await withCheckedContinuation { continuation in
                waiting.append(continuation)
            }
        } else {
            busy = true
        }
    }

    private func leave() {
        if waiting.isEmpty {
            busy = false
        } else {
            waiting.removeFirst().resume()
        }
    }

    func participate(userID: UUID, workshopID: UUID, on db: any Database) async throws {
        await enter()
        defer { leave() }

        try await db.transaction { transaction in
            guard try await User.find(userID, on: transaction) != nil else {
                throw Abort(.notFound, reason: "User not found")
            }
            guard let workshop = try await Workshop.find(workshopID, on: transaction) else {
                throw Abort(.notFound, reason: "Workshop not found")
            }

            let existing = try await Reservation.query(on: transaction)
                .filter(\.$user.$id == userID)
                .filter(\.$workshop.$id == workshopID)
                .first()

            if existing?.status == ReservationStatus.validate.rawValue {
                throw Abort(.conflict, reason: "Reservation already exists")
            }

            let count = try await Reservation.query(on: transaction)
                .filter(\.$workshop.$id == workshopID)
                .filter(\.$status == ReservationStatus.validate.rawValue)
                .count()

            guard count < workshop.maxCapacity else {
                throw Abort(.conflict, reason: "Workshop is full")
            }

            if let existing {
                existing.status = ReservationStatus.validate.rawValue
                try await existing.update(on: transaction)
            } else {
                try await Reservation(
                    workshop: workshopID,
                    user: userID,
                    status: ReservationStatus.validate.rawValue
                ).create(on: transaction)
            }

            workshop.totalSubscribers = count + 1
            try await workshop.update(on: transaction)
        }
    }
    func cancel(id: UUID, userID: UUID, on db: any Database) async throws {
        await enter()
        defer { leave() }

        try await db.transaction { transaction in
            guard let reservation = try await Reservation
                .query(on: transaction)
                .filter(\.$id == id)
                .with(\.$user)
                .first()
            else {
                throw Abort(.notFound)
            }
            
            guard let user = try await User
                .query(on: transaction)
                .filter(\.$id == userID)
                .first()
            else {
                throw Abort(.notFound)
            }
            
            guard reservation.$user.id == userID || user.role == "admin" else {
                throw Abort(.forbidden)
            }
            
            guard reservation.status != ReservationStatus.cancel.rawValue else {
                return
            }

            reservation.status = ReservationStatus.cancel.rawValue
            try await reservation.update(on: transaction)

            guard let workshop = try await Workshop.find(reservation.$workshop.id, on: transaction) else {
                throw Abort(.notFound, reason: "Workshop not found")
            }
            workshop.totalSubscribers = try await Reservation.query(on: transaction)
                .filter(\.$workshop.$id == reservation.$workshop.id)
                .filter(\.$status == ReservationStatus.validate.rawValue)
                .count()
            try await workshop.update(on: transaction)
        }
    }
    func editWorkshop(id: UUID, update: UpdateWorkshopDTO, on db: any Database) async throws -> WorkshopDTO {
        await enter()
        defer { leave() }

        return try await db.transaction { transaction in
            try await update.customValidation(db: transaction)
            guard let workshop = try await Workshop.query(on: transaction)
                .filter(\.$id == id)
                .with(\.$category)
                .first() else {
                throw Abort(.notFound, reason: "Workshop not found")
            }

            let count = try await Reservation.query(on: transaction)
                .filter(\.$workshop.$id == id)
                .filter(\.$status == ReservationStatus.validate.rawValue)
                .count()
            guard update.maxCapacity >= count else {
                throw Abort(.conflict, reason: "Capacity is lower than current reservations")
            }

            workshop.apply(updatedWorkshop: update)
            workshop.totalSubscribers = count
            try await workshop.update(on: transaction)
            guard let saved = try await Workshop.query(on: transaction)
                .filter(\.$id == id)
                .with(\.$category)
                .first() else {
                throw Abort(.notFound, reason: "Workshop not found")
            }
            return try saved.toWorkshopDTO()
        }
    }
    func deleteWorkshop(id: UUID, on db: any Database) async throws {
        await enter()
        defer { leave() }

        try await db.transaction { transaction in
            guard let workshop = try await Workshop.find(id, on: transaction) else {
                throw Abort(.notFound)
            }
            try await Reservation.query(on: transaction)
                .filter(\.$workshop.$id == id)
                .delete()
            try await workshop.delete(on: transaction)
        }
    }
}

private struct ReservationCoordinatorKey: StorageKey {
    typealias Value = ReservationCoordinator
}

extension Application {
    var reservationCoordinator: ReservationCoordinator {
        if let coordinator = storage[ReservationCoordinatorKey.self] {
            return coordinator
        }
        let coordinator = ReservationCoordinator()
        storage[ReservationCoordinatorKey.self] = coordinator
        return coordinator
    }
}
