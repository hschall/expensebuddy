import { Application } from "@hotwired/stimulus"
import FiltersController from "./filters_controller"

const application = Application.start()
application.register("filters", FiltersController)
