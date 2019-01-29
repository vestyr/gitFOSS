# frozen_string_literal: true

class Int4PkStage1Step1of5 < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab::Database.postgresql?

    add_column(:events, :id_new, :bigint)
    install_rename_triggers_for_postgresql('int4_to_int8', :events, :id, :id_new, 'INSERT')
    int4_to_int8_remember_max_value(:events, :id, :id_new)

    add_column(:push_event_payloads, :event_id_new, :bigint)
    install_rename_triggers_for_postgresql('int4_to_int8', :push_event_payloads, :event_id, :event_id_new, 'INSERT')
    int4_to_int8_remember_max_value(:push_event_payloads, :event_id, :event_id_new)

    #execute "alter table public.events set (autovacuum_enabled = false);"
    #execute "alter table public.push_event_payloads set (autovacuum_enabled = false);"
  end

  def down
    return unless Gitlab::Database.postgresql?

    #execute "alter table public.push_event_payloads set (autovacuum_enabled = false);"
    #execute "alter table public.events set (autovacuum_enabled = false);"

    int4_to_int8_forget_max_value(:push_event_payloads, :event_id)
    remove_rename_triggers_for_postgresql(:push_event_payloads, :'int4_to_int8')
    remove_column(:push_event_payloads, :event_id_new)

    int4_to_int8_forget_max_value(:events, :id)
    remove_rename_triggers_for_postgresql(:events, :'int4_to_int8')
    remove_column(:events, :id_new)
  end
end
