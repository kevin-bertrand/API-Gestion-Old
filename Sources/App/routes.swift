import Fluent
import Vapor

func routes(_ app: Application) throws {
    let addressController = AddressController()
    
    try app.register(collection: StaffController(addressController: addressController))
    try app.register(collection: ProductController())
    try app.register(collection: ClientController(addressController: addressController))
    try app.register(collection: PaymentController())
    try app.register(collection: EstimateController(addressController: addressController))
    try app.register(collection: InvoiceController(addressController: addressController))
    try app.register(collection: RevenuesController())
}
