// app/javascript/controllers/index.js
// Importa la instancia y registra todos los *_controller.js automáticamente
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)
