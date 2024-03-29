import APNS
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import JWTKit
import Leaf
import Vapor

class Configuration {
    static var serverHostname = ""
    static var serverPort = 0
}

// configures your application
public func configure(_ app: Application) throws {
    /// config max upload file size
    app.routes.defaultMaxBodySize = "10mb"
    
    // Configure DB
    if app.environment == .testing {
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_DEV_NAME") ?? "vapor_database"
        ), as: .psql)
    } else if app.environment == .production {
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database"
        ), as: .psql)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
    
    // Configuring files middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Leaf configuration
    app.views.use(.leaf)
    
    // APNS Configuration
//    app.apns.configuration = try .init(authenticationMethod: .jwt(key: .private(filePath: Environment.get("APNS_FILE_PATH") ?? ""),
//                                                                  keyIdentifier: JWKIdentifier(string: Environment.get("APNS_KEY_IDENTIFIER") ?? ""),
//                                                                  teamIdentifier: Environment.get("APNS_TEAM_IDENTIFIER") ?? ""),
//                                       topic: "com.desyntic.ios.Gestion",
//                                       environment: .sandbox)
    // Server configuration
    if app.environment == .testing {
        Configuration.serverPort = Environment.get("SERVER_DEV_PORT").flatMap(Int.init(_:)) ?? 8080
    } else {
        Configuration.serverPort = Environment.get("SERVER_PORT").flatMap(Int.init(_:)) ?? 8080
    }
    Configuration.serverHostname = Environment.get("SERVER_HOSTNAME") ?? "127.0.0.1"
    app.http.server.configuration.hostname = Configuration.serverHostname
    app.http.server.configuration.port = Configuration.serverPort
    
    // Migrations
    app.migrations.add(EnumerationsMigration())
    app.migrations.add(PayementMethodMigration())
    app.migrations.add(AddressMigration())
    app.migrations.add(ClientMigration())
    app.migrations.add(EstimateMigration())
    app.migrations.add(InvoiceMigration())
    app.migrations.add(MonthRevenueMigration())
    app.migrations.add(ProductMigration())
    app.migrations.add(StaffMigration())
    app.migrations.add(UserTokenMigration())
    app.migrations.add(YearRevenueMigration())
    app.migrations.add(InternalReferenceMigration())
    app.migrations.add(DeviceMigration())
    app.migrations.add(SiblingsMigration())
    
    // Add default administrator user
    app.migrations.add(DefaultAdministratorMigration(environment: app.environment))
        
    // register routes
    try routes(app)
}
