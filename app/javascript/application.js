// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"
import "bootstrap/dist/js/bootstrap.bundle.min.js"

// Load Bootstrap styles
import "bootstrap/dist/css/bootstrap.min.css"

// Make Bootstrap available globally
window.bootstrap = bootstrap; 