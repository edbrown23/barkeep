import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount", "servings"]

  scale() {
    const servings = Number(this.servingsTarget.value)

    this.amountTargets.forEach((amount) => {
      const scaledAmount = Number(amount.dataset.cocktailScaleBaseAmount) * servings
      amount.textContent = `${this.formatAmount(scaledAmount)} ${amount.dataset.cocktailScaleUnit}`
    })
  }

  formatAmount(amount) {
    return Number(amount.toFixed(3)).toString()
  }
}
