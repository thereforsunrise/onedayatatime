class CreateFeatures < ActiveRecord::Migration[6.0]
  def change
    create_table :features do |t|
      t.string :feature
      t.boolean :enabled
    end
  end
end
