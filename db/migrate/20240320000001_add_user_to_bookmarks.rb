class AddUserToBookmarks < ActiveRecord::Migration[7.1]
  def up
    # Remove existing column if it exists
    remove_column :bookmarks, :user_id if column_exists?(:bookmarks, :user_id)
    
    # Add the column initially as nullable
    add_reference :bookmarks, :user, null: true
    
    # Get or create a default user for existing bookmarks
    default_user = User.find_or_create_by!(
      username: 'default',
      email_address: 'default@example.com'
    ) do |user|
      user.password = SecureRandom.hex(20)
    end
    
    # Assign all existing bookmarks to the default user
    execute <<-SQL
      UPDATE bookmarks 
      SET user_id = #{default_user.id}
      WHERE user_id IS NULL
    SQL
    
    # Now we can add the NOT NULL constraint
    change_column_null :bookmarks, :user_id, false
    
    # Finally add the foreign key
    add_foreign_key :bookmarks, :users
  end

  def down
    remove_reference :bookmarks, :user, foreign_key: true
  end
end 
