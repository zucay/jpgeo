class AddIndexToTky2jgds < ActiveRecord::Migration
  def change
    add_index :tky2jgds, :meshcode
  end
end
