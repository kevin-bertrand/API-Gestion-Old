import Fluent
import Vapor

func routes(_ app: Application) throws {
    let addressController = AddressController()
    
    try app.register(collection: StaffController(addressController: addressController))
    try app.register(collection: ProductController())
    try app.register(collection: ClientController(addressController: addressController))
    try app.register(collection: PaymentController())
}
