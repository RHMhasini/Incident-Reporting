# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ConfigureIncidentPriorities, type: :db_migration do
  it 'upgrades legacy names in place, preserves ticket references and sets Medium as default' do
    %w[Low Medium High].zip(['1 low', '2 normal', '3 high']).each do |name, legacy_name|
      Ticket::Priority.find_by!(name: name).update!(name: legacy_name)
    end
    priority = Ticket::Priority.find_by!(name: '2 normal')
    ticket = create(:ticket, priority: priority, state: Ticket::State.find_by!(name: 'Reported'))
    ids = Ticket::Priority.pluck(:id)

    migrate

    expect(ticket.reload.priority_id).to eq(priority.id)
    expect(priority.reload.name).to eq('Medium')
    expect(Ticket::Priority.where(default_create: true).pluck(:id)).to eq([priority.id])
    expect(Ticket::Priority.where(active: true).pluck(:name)).to match_array(%w[Low Medium High Critical])
    expect(Ticket::Priority.pluck(:id)).to include(*ids)
    expect(ObjectManager::Attribute.get(object: 'Ticket', name: 'priority_id').data_option[:default]).to eq(priority.id)
    expect { migrate }.not_to change(Ticket::Priority, :count)
  end

  it 'creates a missing Critical priority without reusing an existing priority ID' do
    priority = Ticket::Priority.find_by!(name: 'Critical')
    priority.update!(name: 'Legacy custom priority')

    migrate

    expect(Ticket::Priority.find_by!(name: 'Critical').id).not_to eq(priority.id)
    expect(priority.reload).not_to be_active
  end
end
