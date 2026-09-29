# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::EmailParser, type: :model do
  let(:group) { create(:group, follow_up_possible: 'yes') }

  Ticket::State::INCIDENT_TRANSITIONS.each_key do |state_name|
    context "with a #{state_name} incident" do
      let(:ticket) do
        create(:ticket, group: group, state: Ticket::State.find_by!(name: state_name),
                        priority: Ticket::Priority.find_by!(default_create: true))
      end

      it 'creates a public customer article without changing the incident state' do
        message = <<~MAIL
          From: #{ticket.customer.email}
          To: support@example.com
          Subject: #{ticket.subject_build('Follow-up')}
          Message-ID: <#{SecureRandom.uuid}@example.com>

          Additional incident information.
        MAIL

        result = nil
        expect do
          result = described_class.new.process({ group_id: group.id, trusted: false }, message)
        end.not_to change { ticket.reload.state_id }
        expect(result[0].id).to eq(ticket.id)
        expect(result[1]).to be_persisted
        expect(result[1]).not_to be_internal
        expect(result[1].sender.name).to eq('Customer')
      end
    end
  end
end
