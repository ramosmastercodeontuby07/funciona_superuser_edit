# db/migrate/XXXXXXXXXXXX_add_section_to_products.rb
class AddSectionToProducts < ActiveRecord::Migration[7.1]
  def change
    # 0 = bebidas, 1 = suplementos
    add_column :products, :section, :integer, default: 1, null: false
    add_index  :products, :section
  end
end
