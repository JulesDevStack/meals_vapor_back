import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }
    
    app.get("testExample") { req async -> Bool in
        true
    }
    
    try app.register(collection: WorkshopController())
    try app.register(collection: UserController())
    try app.register(collection: ReservationController())
}
