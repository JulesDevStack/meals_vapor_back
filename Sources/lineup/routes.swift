import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }
    
    try app.register(collection: WorkshopController())
    try app.register(collection: UserController())
}
