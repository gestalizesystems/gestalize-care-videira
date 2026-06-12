class EnablePgcrypto < ActiveRecord::Migration[7.2]
  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
  end

  def down
    disable_extension "pgcrypto"
  end
end
