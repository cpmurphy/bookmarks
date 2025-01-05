class AddColsToBookmark < ActiveRecord::Migration[8.0]
  def change
    add_column :bookmarks, :user_id, :integer
    add_column :bookmarks, :private, :boolean
  end
end
