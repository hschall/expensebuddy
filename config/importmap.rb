pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chartkick"
pin "Chart.bundle", to: "chart.js", preload: true




