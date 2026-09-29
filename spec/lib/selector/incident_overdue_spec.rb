# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Incident overdue selection' do
  let(:active_states) { ['Reported', 'Triaged', 'In Progress', 'Mitigated', 'Monitoring', 'Resolved'] }
  let(:condition) do
    {
      'ticket.target_resolution_date' => { operator: 'before today' },
      'ticket.state_id' => { operator: 'is', value: Ticket::State.where(name: active_states).pluck(:id) },
    }
  end

  before do
    Setting.set('timezone_default', 'Asia/Colombo')
    travel_to Time.utc(2026, 9, 28, 18, 30)
  end

  it 'uses the configured calendar date at midnight rather than a rolling timestamp' do
    query, binds = Ticket.selector2sql(condition)
    expect(query).to include('target_resolution_date', '< ?')
    expect(binds).to include(Date.new(2026, 9, 29))
    expect(binds.grep(Time)).to be_empty
  end

  it 'uses the same exclusive day boundary in the search index' do
    query = Selector::SearchIndex.new(selector: condition, options: {}).get
    expect(query.to_json).to include('"target_resolution_date":{"lt":"2026-09-29T00:00:00Z"}')
  end

  it 'includes past dates only in active states and does not modify tickets' do
    tickets = (active_states + ['Closed', 'Cancelled', 'merged']).map do |state_name|
      create(:ticket, state: Ticket::State.find_by!(name: state_name),
                      priority: Ticket::Priority.find_by!(default_create: true),
                      target_resolution_date: Date.new(2026, 9, 28))
    end
    [nil, Date.new(2026, 9, 29), Date.new(2026, 9, 30)].each do |date|
      tickets << create(:ticket, state: Ticket::State.find_by!(name: 'In Progress'),
                                 priority: Ticket::Priority.find_by!(default_create: true),
                                 target_resolution_date: date)
    end
    snapshots = tickets.map(&:attributes)

    _, matches = Ticket.selectors(condition, limit: 100)
    expect(matches.where(id: tickets.map(&:id)).pluck(:id)).to match_array(tickets.first(6).map(&:id))
    expect(tickets.map { |ticket| ticket.reload.attributes }).to eq(snapshots)

    reopened = tickets.find { |ticket| ticket.state.name == 'Closed' }
    reopened.update!(state: Ticket::State.find_by!(name: 'In Progress'))
    _, matches = Ticket.selectors(condition, limit: 100)
    expect(matches.pluck(:id)).to include(reopened.id)
    expect(reopened.target_resolution_date).to eq(Date.new(2026, 9, 28))
  end
end
