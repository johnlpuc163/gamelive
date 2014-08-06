class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels do |t|
      t.string   "title"
      t.integer  "viewers"
      t.string   "player"
      t.string   "link"
      t.string   "image"
      t.integer  "game_id"
      t.string   "source"
      t.timestamps
    end
  end
end
