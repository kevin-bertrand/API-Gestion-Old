import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import Leaf
import Queues
import QueuesRedisDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    /// config max upload file size
    app.routes.defaultMaxBodySize = "10mb"
    
    // Configure DB
    if app.environment == .production {
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
    
    // Server configuration
    app.http.server.configuration.hostname = Environment.get("SERVER_HOSTNAME") ?? "127.0.0.1"
    app.http.server.configuration.port = Environment.get("SERVER_PORT").flatMap(Int.init(_:)) ?? 8080
    
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
    app.migrations.add(SiblingsMigration())
    
    // Add default administrator user
    app.migrations.add(DefaultAdministratorMigration())
    
    // Configure jobs
//
    let configuration = try RedisConfiguration(hostname: "127.0.0.1",
                                               port: 6379,
                                               password: "eYVX7EwVmmxKPCDmwMtyKVge8oLd2t81",
                                               pool: .init(connectionRetryTimeout: .milliseconds(60)))
    app.queues.use(.redis(configuration))
    app.queues.schedule(InvoiceStatusJob())
        .minutely()
        .at(0)
    
    try app.queues.startInProcessJobs()
    try app.queues.startScheduledJobs()
    
    // register routes
    try routes(app)
}
