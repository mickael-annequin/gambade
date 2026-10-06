// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import { confirmDialog } from "confirm_dialog"

// data-turbo-confirm opens our styled window instead of the phone's plain one.
Turbo.config.forms.confirm = (message) => confirmDialog(message)
