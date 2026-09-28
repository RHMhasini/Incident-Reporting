# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::Ticket::Edit < FormUpdater::Updater
  include FormUpdater::Concerns::PreparesTicketSignature
  include FormUpdater::Concerns::AppliesTaskbarState
  include FormUpdater::Concerns::AppliesTicketSharedDraft
  include FormUpdater::Concerns::ChecksCoreWorkflow
  include FormUpdater::Concerns::HasSecurityOptions
  include FormUpdater::Concerns::StoresTaskbarState
  include FormUpdater::Updater::Ticket::Concerns::HasOwnerId

  core_workflow_screen 'edit'

  def self.required_permissions
    %w[ticket.agent ticket.customer]
  end

  apply_shared_draft_group_keys %i[article ticket]
  apply_state_group_keys %w[ticket article]
  store_state_collect_group_key 'ticket'
  store_state_group_keys ['article']

  def object_type
    ::Ticket
  end

  def handle_updater_flags
    flags[:newArticlePresent] = result['articleType'].present? || (!meta.dig(:additional_data, 'applyTaskbarState') && data.dig('article', 'articleType').present?)

    flags[:hasSharedDraft] = check_shared_draft
  end

  def after_store_taskbar_preperation(state)
    # Remove owner_id when it's the system user and this is also the current ticket value.
    if object && state['ticket']&.key?('owner_id') && state.dig('ticket', 'owner_id').nil? && object.owner_id == 1
      state['ticket'].delete('owner_id')
    end

    return if state.dig('article', 'articleType').nil?

    state['article']['type'] = state['article'].delete('articleType')
  end

  private

  def check_shared_draft
    current_group_id = data['group_id']
    return false if current_group_id.nil?

    current_group = ::Group.find_by(id: current_group_id)
    return false if current_group.nil? || !current_group.shared_drafts

    current_user.group_access?(current_group, 'change')
  end
end
