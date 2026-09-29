# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::ResetsTicketState, type: :model do
  shared_examples 'preserves the incident state' do |state_name, sender_name|
    let(:ticket) do
      create(:ticket, state: Ticket::State.find_by!(name: state_name),
                      priority: Ticket::Priority.find_by!(default_create: true))
    end

    it 'persists the public article without transitioning the incident' do
      article = build(:ticket_article, ticket: ticket, sender_name: sender_name,
                                       type_name: 'web', internal: false)

      expect { article.save! }.not_to change { ticket.reload.state_id }
      expect(article).to be_persisted
      expect(article.reload).not_to be_internal
    end
  end

  context 'when an agent replies to a Reported incident' do
    include_examples 'preserves the incident state', 'Reported', 'Agent'
  end

  %w[Resolved Closed Cancelled].each do |state_name|
    context "when a customer follows up on a #{state_name} incident" do
      include_examples 'preserves the incident state', state_name, 'Customer'
    end
  end
end
