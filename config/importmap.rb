# Pin npm packages by running ./bin/importmap

pin "application"
pin "walk_storage"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "mapbox-gl" # @3.32.0
pin "exifr" # @7.1.3
pin "chart.js" # @4.5.1 (self-contained build from esm.sh, see the top of vendor/javascript/chart.js.js)
