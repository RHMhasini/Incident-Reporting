# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Ticket::ChecksIncidentTransitions
  extend ActiveSupport::Concern

  private

  def validate_workflows
    # Native merge, channels, triggers and article callbacks do not submit a form screen.
    # Apply the business transitions at the same request boundary as CoreWorkflow.
    if screen.present? && UserInfo.current_user_id && will_save_change_to_state_id?
      saved_ticket = persisted? ? Ticket.find(id) : self
      allowed = Ticket::State.incident_state_ids(saved_ticket, UserInfo.current_user)
      if !allowed.include?(state_id)
        raise Exceptions::ApplicationModel.new(self, "Invalid incident state transition to '#{state_id}'!")
      end
    end

    super
  end
end
