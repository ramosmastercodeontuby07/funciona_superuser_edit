// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"

export const application = Application.start()

// Activa debug si pones localStorage.setItem("stimulus:debug", "true")
application.debug = (localStorage.getItem("stimulus:debug") === "true")

// Exponlo global por si quieres inspeccionar en consola
window.Stimulus = application

// Soporta import por default o nombrado
export default application
