class RenamePrivateColumnInBookmarks < ActiveRecord::Migration[7.1]
  def change
    rename_column :bookmarks, :private, :is_private
  end
end 
