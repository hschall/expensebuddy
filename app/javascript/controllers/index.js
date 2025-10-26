// app/javascript/controllers/index.js

import { application } from "../application"
import FiltersController from "./filters_controller"

application.register("filters", FiltersController)
