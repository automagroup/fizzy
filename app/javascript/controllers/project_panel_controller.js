import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = [ "dialog" ]
  static values = { direct: Boolean, fallbackUrl: String }

  connect() {
    this.openedFromFrame = false
    this.restoringLocation = false
  }

  open(event) {
    if (event.target.id !== "project_panel") return

    this.openedFromFrame = !this.directValue
    if (!this.dialogTarget.open) this.dialogController.open()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.dialogController.close()
  }

  cancel(event) {
    event.preventDefault()
    this.dialogController.close()
  }

  restoreLocation() {
    if (this.restoringLocation) return

    this.restoringLocation = true
    if (this.openedFromFrame) {
      window.history.back()
    } else {
      Turbo.visit(this.fallbackUrlValue, { action: "replace" })
    }
  }

  get dialogController() {
    return this.application.getControllerForElementAndIdentifier(this.element, "dialog")
  }
}
