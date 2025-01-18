import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "count", "startId"]

  connect() {
    this.updatePreview()
  }

  updatePreview() {
    const startId = this.startIdTarget.value
    if (!startId) {
      this.showAllBookmarksMessage()
      return
    }

    fetch(`/tools/preview_export?start_id=${startId}`)
      .then(response => response.json())
      .then(data => {
        this.renderPreview(data.bookmarks, data.total)
      })
      .catch(error => {
        console.error('Preview update failed:', error)
        this.showAllBookmarksMessage()
      })
  }

  showAllBookmarksMessage() {
    fetch('/tools/preview_export')
      .then(response => response.json())
      .then(data => {
        this.previewTarget.querySelector('.preview-items').innerHTML = 
          '<div class="preview-message">All bookmarks will be exported</div>'
        this.countTarget.textContent = 
          `${data.total} bookmark${data.total === 1 ? '' : 's'} will be exported`
      })
      .catch(error => {
        console.error('Preview count fetch failed:', error)
      })
  }

  renderPreview(bookmarks, total) {
    const items = total <= 2 ? this.renderTwoBookmarks(bookmarks) :
                 total === 1 ? this.renderOneBookmark(bookmarks[0]) :
                 this.renderManyBookmarks(bookmarks)

    this.previewTarget.querySelector('.preview-items').innerHTML = items
    this.countTarget.textContent = 
      `${total} bookmark${total === 1 ? '' : 's'} will be exported`
  }

  renderOneBookmark(bookmark) {
    return this.renderBookmarkItem(bookmark)
  }

  renderTwoBookmarks(bookmarks) {
    return bookmarks.map(b => this.renderBookmarkItem(b)).join('')
  }

  renderManyBookmarks(bookmarks) {
    return `
      ${this.renderBookmarkItem(bookmarks[0])}
      <div class="preview-ellipsis">⋮</div>
      ${this.renderBookmarkItem(bookmarks[1])}
    `
  }

  renderBookmarkItem(bookmark) {
    return `
      <div class="preview-item">
        <span class="preview-date">${bookmark.date}</span>
        ${bookmark.title}
      </div>
    `
  }
} 
