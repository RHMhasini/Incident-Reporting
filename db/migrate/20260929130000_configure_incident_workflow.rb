# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ConfigureIncidentWorkflow < ActiveRecord::Migration[8.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    { 'New' => 'Reported', 'In progress' => 'In Progress' }.each do |old_name, new_name|
      next if Ticket::State.exists?(name: new_name)

      Ticket::State.find_by(name: old_name)&.update!(name: new_name)
    end

    Ticket::State::INCIDENT_TRANSITIONS.each_key do |name|
      type = if name == 'Reported'
               'new'
             elsif %w[Closed Cancelled].include?(name)
               'closed'
             else
               'open'
             end
      state = Ticket::State.find_or_initialize_by(name: name)
      state.callback_loop = true
      state.assign_attributes(
        state_type: Ticket::StateType.find_by!(name: type), active: true,
        default_create: name == 'Reported', default_follow_up: name == 'In Progress',
        default_close: name == 'Closed', ignore_escalation: type == 'closed',
        created_by_id: state.created_by_id || 1, updated_by_id: 1,
      )
      state.save!
    end

    # Keep all IDs, ticket associations and historical states; do not map old business meanings.
    Ticket::State.where.not(name: Ticket::State::INCIDENT_TRANSITIONS.keys + ['merged']).find_each do |state|
      state.callback_loop = true
      state.update!(active: false, default_create: false, default_follow_up: false, default_close: false)
    end

    Ticket::State.update_state_field_configuration
    attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'state_id')
    attribute.data_option[:default] = Ticket::State.find_by!(default_create: true).id
    attribute.screens[:create_middle].each_value do |screen|
      screen[:default] = attribute.data_option[:default]
    end
    attribute.screens[:edit]['ticket.customer'][:default] = Ticket::State.find_by!(default_follow_up: true).id
    attribute.save!
    Rails.cache.clear
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Incident states may already be referenced by tickets and history.'
  end
end
