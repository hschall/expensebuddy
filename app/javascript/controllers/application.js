// Load Chartkick with Chart.js
import "chartkick"
import "chart.js"

// Turbo (Hotwire)
import "@hotwired/turbo-rails"

// Stimulus setup
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-loading"

const application = Application.start()
application.debug = false
window.Stimulus = application

// Load all controllers from app/javascript/controllers
import "controllers"
