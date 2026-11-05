import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor
import Gatekeeper

/// configures your application
func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "lineup",
        tlsConfiguration: nil
    ), as: .mysql)
    
    app.caches.use(.memory)
    _ = app.reservationCoordinator
    app.gatekeeper.config = .init(maxRequests: 100, per: .minute)
    app.middleware.use(GatekeeperMiddleware())
    

//    app.migrations.add(CreateCategory())
//    app.migrations.add(CreateWorkshop())
//    app.migrations.add(CreateUser())
//    app.migrations.add(CreateReservation())
    
    // configure URL decoder to use ISO 8601 format
    let decoderConfiguration = URLEncodedFormDecoder(
        configuration: .init(dateDecodingStrategy: .iso8601)
    )
    ContentConfiguration.global.use(urlDecoder: decoderConfiguration)

    app.http.server.configuration.port = 8081
    
    let corsMiddleware = CORSMiddleware(
        configuration: CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
            allowedHeaders: [.accept, .authorization, .contentType, .origin]
        )
    )
    
    app.middleware.use(corsMiddleware)
    
    // register routes
    try routes(app)
}
