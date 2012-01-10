class CreatePostalCodes < ActiveRecord::Migration
  def change
    create_table :postal_codes do |t|
      t.string :uid
      t.string :old_postal_code
      t.string :postal_code
      t.string :pref_kana
      t.string :city_kana
      t.string :town_kana
      t.string :pref
      t.string :city
      t.string :town
      t.integer :has_multiple_postal_code
      t.integer :multiple_koaza
      t.integer :has_chome
      t.integer :has_chome
      t.integer :multiple_town
      t.integer :has_update
      t.integer :update_reason
      t.timestamps
    end
  end
end
