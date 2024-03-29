import Fluent
import Leaf
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
    try app.register(collection: InternalReferenceController())
    try app.register(collection: WidgetController())
    try app.register(collection: TaxController())
}
