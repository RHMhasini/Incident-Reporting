# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class EnableCustomerIncidentPriority < ActiveRecord::Migration[8.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'priority_id')
    attribute.screens[:create_middle]['ticket.customer'] = { null: false, item_class: 'column' }
    attribute.save!
    Rails.cache.clear
  end

  def down
    return if !Setting.exists?(name: 'system_init_done')

    attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'priority_id')
    attribute.screens[:create_middle].delete('ticket.customer')
    attribute.save!
    Rails.cache.clear
  end
end
