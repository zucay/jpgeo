class CreateTky2jgds < ActiveRecord::Migration
  def change
    create_table :tky2jgds do |t|
      t.string :meshcode
      t.float :dB
      t.float :dL

      t.timestamps
    end
  end
end
