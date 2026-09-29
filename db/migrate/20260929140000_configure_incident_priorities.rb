# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ConfigureIncidentPriorities < ActiveRecord::Migration[8.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    names = { 'Low' => '1 low', 'Medium' => '2 normal', 'High' => '3 high', 'Critical' => nil }
    names.each do |name, legacy_name|
      priority = Ticket::Priority.find_by(name: name)
      priority ||= Ticket::Priority.find_by(name: legacy_name) if legacy_name
      priority ||= Ticket::Priority.new
      priority.callback_loop = true
      priority.assign_attributes(
        name: name, active: true, default_create: name == 'Medium',
        created_by_id: priority.created_by_id || 1, updated_by_id: 1,
      )
      priority.save!
    end

    # Preserve references to retired priorities without remapping historical tickets.
    Ticket::Priority.where.not(name: names.keys).find_each do |priority|
      priority.callback_loop = true
      priority.update!(active: false, default_create: false)
    end

    attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'priority_id')
    attribute.data_option[:default] = Ticket::Priority.find_by!(name: 'Medium').id
    attribute.save!
    Rails.cache.clear
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Incident priorities may be referenced by tickets and history.'
  end
end
