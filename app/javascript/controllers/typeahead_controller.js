import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hiddenInput"]

  connect() {
    this.timeout = null
    this.hideResults()
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value

    if (query.length < 2) {
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => {
      fetch(`/tools/search?query=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      .then(response => response.json())
      .then(data => {
        this.showResults(data)
      })
    }, 300)
  }

  showResults(bookmarks) {
    this.resultsTarget.innerHTML = bookmarks.map(bookmark => `
      <div class="typeahead-item"
           data-action="click->typeahead#select"
           data-id="${bookmark.id}">
        <div class="typeahead-title">${bookmark.title}</div>
        <div class="typeahead-meta">
          ${bookmark.date} - ${bookmark.url}
        </div>
      </div>
    `).join('')

    this.resultsTarget.classList.remove('hidden')
  }

  hideResults() {
    this.resultsTarget.classList.add('hidden')
  }

  select(event) {
    const id = event.currentTarget.dataset.id
    const title = event.currentTarget.querySelector('.typeahead-title').textContent
    this.inputTarget.value = title
    this.hiddenInputTarget.value = id
    this.hideResults()
  }

  // Hide results when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
