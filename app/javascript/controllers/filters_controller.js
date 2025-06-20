import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  applyCycleMonth(event) {
    const month = event.target.value
    const params = new URLSearchParams()
    if (month) params.append("cycle_month", month)

    Turbo.visit(`${this.currentPath()}?${params.toString()}`, { responseType: "turbo-stream" })
  }

  applyManual() {
    const person = document.querySelector("select[name='person']").value
    const category = document.querySelector("select[name='category_id']").value
    const description = document.querySelector("input[name='description']").value
    const cycle_month = document.querySelector("select[name='cycle_month']").value

    const params = new URLSearchParams()
    if (person) params.append("person", person)
    if (category) params.append("category_id", category)
    if (description) params.append("description", description)
    if (cycle_month) params.append("cycle_month", cycle_month)

    Turbo.visit(`${this.currentPath()}?${params.toString()}`, { responseType: "turbo-stream" })
  }

  reset() {
    document.querySelector("select[name='person']").value = ""
    document.querySelector("select[name='category_id']").value = ""
    document.querySelector("input[name='description']").value = ""
    document.querySelector("select[name='cycle_month']").value = ""

    Turbo.visit(this.currentPath(), { responseType: "turbo-stream" })
  }

  currentPath() {
    return window.location.pathname.replace(/\/+$/, "") // removes trailing slashes
  }
}
