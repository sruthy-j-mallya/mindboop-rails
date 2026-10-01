# Switches users.id from bigint to uuid while preserving every existing row
# and its refresh tokens. Runs in a single transaction, so a failure part-way
# leaves the schema untouched. Integer ids can't be recovered afterwards, so
# this is irreversible.
class ConvertUsersIdToUuid < ActiveRecord::Migration[8.1]
  def up
    # gen_random_uuid() is built into PostgreSQL 13+.
    add_column :users, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false

    # Point refresh tokens at the new user uuid before dropping the old key.
    add_column :refresh_tokens, :user_uuid, :uuid
    execute <<~SQL
      UPDATE refresh_tokens
      SET user_uuid = users.uuid
      FROM users
      WHERE refresh_tokens.user_id = users.id
    SQL
    change_column_null :refresh_tokens, :user_uuid, false

    remove_foreign_key :refresh_tokens, :users
    remove_column :refresh_tokens, :user_id
    rename_column :refresh_tokens, :user_uuid, :user_id

    # Swap the primary key.
    execute "ALTER TABLE users DROP CONSTRAINT users_pkey"
    remove_column :users, :id
    rename_column :users, :uuid, :id
    execute "ALTER TABLE users ADD PRIMARY KEY (id)"

    add_index :refresh_tokens, :user_id
    add_foreign_key :refresh_tokens, :users
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
