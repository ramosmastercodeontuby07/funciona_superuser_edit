# db/migrate/XXXXXXXXXXXX_rename_section_to_product_section_in_products.rb
class RenameSectionToProductSectionInProducts < ActiveRecord::Migration[7.1]
  def change
    rename_column :products, :section, :product_section
    add_index :products, :product_section unless index_exists?(:products, :product_section)
  end
end
