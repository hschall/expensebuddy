import "chartkick/chart.js"


// Stimulus setup (leave as-is below)
import { Application } from "@hotwired/stimulus"

const application = Application.start()
application.debug = false
window.Stimulus   = application

export { application }

