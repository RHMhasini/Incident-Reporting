# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CompleteIncidentTicketAttributes < ActiveRecord::Migration[8.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    add_incident_columns
    migrate_engineering_owners
    configure_incident_attributes

    ObjectManager::Attribute.get(object: 'Ticket', name: 'type').update!(active: true)

    # Keep the eight incident states; merging needs a separate, non-selectable technical state.
    state_type = Ticket::StateType.find_by!(name: 'merged')
    if !Ticket::State.exists?(state_type_id: state_type.id)
      Ticket::State.create!(name: 'merged', state_type_id: state_type.id, ignore_escalation: true,
                           created_by_id: 1, updated_by_id: 1)
    end

    Rails.cache.clear
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Incident fields and user assignments must be preserved.'
  end

  private

  def add_incident_columns
    {
      incident_category:      [:string, { limit: 255 }],
      engineering_owner:      [:string, { limit: 150 }],
      target_resolution_date: [:date, {}],
      resolution_details:     [:string, { limit: 5000 }],
      release_date:           [:date, {}],
    }.each do |name, (type, options)|
      next if column_exists?(:tickets, name)

      add_column :tickets, name, type, **options, null: true
    end
    Ticket.reset_column_information
  end

  def migrate_engineering_owners
    attribute = ObjectManager::Attribute.get(object: 'Ticket', name: 'engineering_owner')
    return if attribute && attribute.data_type != 'input'

    # Free text must not silently disappear or be guessed when switching to a user relation.
    values = Ticket.where.not(engineering_owner: [nil, '']).distinct.pluck(:engineering_owner)
    assignments = values.to_h do |value|
      identifier = value.strip
      next [value, nil] if identifier.blank?

      user = User.find_by(id: identifier) if identifier.match?(%r{\A[1-9]\d*\z})
      if !user
        matches = User.where('login = :identifier OR email = :identifier', identifier: identifier).limit(2).to_a
        user = matches.first if matches.one?
      end
      if !user
        raise "Engineering Owner contains unmapped free text. Before retrying this migration, " \
              "replace existing tickets' engineering_owner values with unique user logins, emails, or IDs. " \
              'No assignments have been discarded.'
      end

      [value, user.id.to_s]
    end

    assignments.each do |value, user_id|
      Ticket.where(engineering_owner: value).update_all(engineering_owner: user_id) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def configure_incident_attributes
    add_attribute(
      'incident_category', 'Category', 'select', 21,
      {
        default: '',
        options: {
          'bug'             => 'Bug',
          'login_access'    => 'Login/Access',
          'feature_request' => 'Feature Request',
          'general_support' => 'General Support',
        },
        nulloption: true, multiple: false, null: false, translate: true,
      },
      {
        create_middle: { '-all-' => { null: false } },
        edit:          { 'ticket.agent' => { null: false } },
      },
    )

    edit_screen = { edit: { 'ticket.agent' => { null: true } } }
    add_attribute(
      'engineering_owner', 'Engineering Owner', 'select', 2010,
      {
        default: '', relation: 'User', relation_condition: { roles: 'Agent' },
        nulloption: true, multiple: false, maxlength: 150, null: true,
        translate: false, permission: ['ticket.agent'],
      },
      edit_screen,
    )
    add_attribute(
      'target_resolution_date', 'Target Resolution Date', 'date', 2020,
      { null: true, permission: ['ticket.agent'] }, edit_screen,
    )
    add_attribute(
      'resolution_details', 'Resolution Details', 'textarea', 2030,
      { maxlength: 5000, rows: 6, null: true, permission: ['ticket.agent'] }, edit_screen,
    )
    add_attribute(
      'release_date', 'Release Date', 'date', 2040,
      { null: true, permission: ['ticket.agent'] }, edit_screen,
    )
  end

  def add_attribute(name, display, data_type, position, data_option, screens)
    ObjectManager::Attribute.add(
      force: true, object: 'Ticket', name: name, display: display,
      data_type: data_type, position: position, data_option: data_option, screens: screens,
      editable: true, active: true, to_create: false, to_migrate: false,
      to_delete: false, to_config: false, data_option_new: {},
      created_by_id: 1, updated_by_id: 1,
    )
  end
end
