class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks do |t|
      t.string :url
      t.string :title
      t.text :description
      t.string :tags

      t.timestamps
    end
  end
end
