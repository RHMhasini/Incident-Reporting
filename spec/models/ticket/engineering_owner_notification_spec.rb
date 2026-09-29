# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::PerformChanges::Action::NotificationEmail, type: :model do
  let(:group) { create(:group) }
  let(:engineer) { create(:agent, groups: [group]) }
  let(:ticket) { build(:ticket, group: group, engineering_owner: engineer.id.to_s) }
  let(:settings) { { 'recipient' => ['ticket_engineering_owner'], 'internal' => false } }
  let(:action) { described_class.new(ticket, settings, {}) }

  it 'resolves the current engineering owner without retaining the previous recipient' do
    expect(action.send(:recipients_raw)).to eq([engineer.email])
    replacement = create(:agent, groups: [group])
    ticket.engineering_owner = replacement.id.to_s
    expect(action.send(:recipients_raw)).to eq([replacement.email])
  end

  it 'does not notify anyone when the assignment is cleared' do
    ticket.engineering_owner = nil
    expect(action.send(:recipients_raw)).to be_empty
    expect(action).not_to receive(:send_email_notification)
    action.execute
  end

  it 'rejects customer, inactive, system, missing and malformed user IDs' do
    customer = create(:customer)
    inactive = create(:agent, active: false, groups: [group])
    [customer.id.to_s, inactive.id.to_s, '1', '0', "#{engineer.id}invalid"].each do |identifier|
      ticket.engineering_owner = identifier
      expect(action.send(:recipients_raw)).to be_empty
    end
  end

  it 'requires agent read access to the ticket group' do
    ticket.engineering_owner = create(:agent, groups: []).id.to_s
    expect(action.send(:recipients_raw)).to be_empty
  end

  it 'excludes other recipients even when a rule includes the customer' do
    settings['recipient'] += ['ticket_customer', 'article_last_sender', 'ticket_engineering_owner']
    expect(action.send(:recipients_raw)).to eq([engineer.email])
  end

  it 'forces assignment notification articles to remain internal and system-authored' do
    allow(action).to receive_messages(article_subject: 'Assignment', article_preferences: {})
    params = action.send(:article_params, 'Assigned to you', nil)
    expect(params[:internal]).to be true
    expect(params[:sender].name).to eq('System')
    expect(params).not_to have_key(:state_id)
  end

  it 'preserves the native owner recipient when engineering notifications are not selected' do
    ticket.owner = engineer
    settings['recipient'] = ['ticket_owner']
    expect(action.send(:recipients_raw)).to eq([engineer.email])
  end
end
