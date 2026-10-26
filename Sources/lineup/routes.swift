import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        return "Hello, world!"
    }
    
    try app.register(collection: WorkshopController())
    try app.register(collection: UserController())
    try app.register(collection: ReservationController())
}
