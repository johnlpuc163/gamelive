class AddColumnsToGame < ActiveRecord::Migration
  def change
    add_column :games, :image, :string
  end
end
