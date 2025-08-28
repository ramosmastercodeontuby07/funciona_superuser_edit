# db/migrate/20250812002601_add_fingerprint_to_users_and_members.rb
class AddFingerprintToUsersAndMembers < ActiveRecord::Migration[8.0]
  def up
    add_fp_columns(:users)

    if table_exists?(:customers)
      say "Adding fingerprint columns to customers...", true
      add_fp_columns(:customers)
    else
      say "Table :customers not found. Skipping.", true
    end
  end

  def down
    remove_fp_columns(:users)
    remove_fp_columns(:customers) if table_exists?(:customers)
  end

  private

  def add_fp_columns(table)
    add_column table, :fingerprint_template,    :text     unless column_exists?(table, :fingerprint_template)
    add_column table, :fingerprint_algo,        :string   unless column_exists?(table, :fingerprint_algo)
    add_column table, :fingerprint_updated_at,  :datetime unless column_exists?(table, :fingerprint_updated_at)
    add_column table, :fingerprint_enabled,     :boolean, default: true unless column_exists?(table, :fingerprint_enabled)
  end

  def remove_fp_columns(table)
    remove_column table, :fingerprint_template   if column_exists?(table, :fingerprint_template)
    remove_column table, :fingerprint_algo       if column_exists?(table, :fingerprint_algo)
    remove_column table, :fingerprint_updated_at if column_exists?(table, :fingerprint_updated_at)
    remove_column table, :fingerprint_enabled    if column_exists?(table, :fingerprint_enabled)
  end
end
