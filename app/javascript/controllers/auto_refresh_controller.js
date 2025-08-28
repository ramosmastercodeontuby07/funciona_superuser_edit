// app/javascript/controllers/auto_refresh_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = { url: String, interval: { type: Number, default: 10000 } }

  connect() {
    this.load()
    this.timer = setInterval(() => this.load(), this.intervalValue)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  async load() {
    try {
      const resp = await fetch(this.urlValue, { headers: { "Accept": "text/html" } })
      const html = await resp.text()
      this.containerTarget.innerHTML = html
    } catch (e) {
      // opcional: console.error(e)
    }
  }
}
