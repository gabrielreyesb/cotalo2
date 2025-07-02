// Load all the controllers within this directory and all subdirectories. 
// Controller files must be named *_controller.js.

import { Application } from "@hotwired/stimulus"

import FlashController from "./flash_controller.js"
import CustomerSearchController from "./customer_search_controller.js"
import QuoteProductsController from "./quote_products_controller.js"

const application = Application.start()

application.register("flash", FlashController)
application.register("customer-search", CustomerSearchController)
application.register("quote-products", QuoteProductsController) 