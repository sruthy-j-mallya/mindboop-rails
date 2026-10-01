# Switches refresh_tokens.id from bigint to uuid. Nothing references this key,
# so existing rows just get a fresh uuid. Irreversible, like the users switch.
class ConvertRefreshTokensIdToUuid < ActiveRecord::Migration[8.1]
  def up
    add_column :refresh_tokens, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false

    execute "ALTER TABLE refresh_tokens DROP CONSTRAINT refresh_tokens_pkey"
    remove_column :refresh_tokens, :id
    rename_column :refresh_tokens, :uuid, :id
    execute "ALTER TABLE refresh_tokens ADD PRIMARY KEY (id)"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
