# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Validations::ObjectManager::AttributeValidator::IncidentInternal < Validations::ObjectManager::AttributeValidator::Backend
  FIELDS = %w[engineering_owner target_resolution_date resolution_details release_date].freeze

  def validate
    return if !record.is_a?(Ticket)
    return if FIELDS.exclude?(attribute.name)
    return if !record.will_save_change_to_attribute?(attribute.name)

    user = UserInfo.current_user
    # Match native validators' handling of system jobs and migrations.
    return if !user || user.id == 1

    access = record.new_record? ? 'create' : 'change'
    if !user.permissions?('ticket.agent') || !user.group_access?(record.group_id, access)
      invalid_because_attribute(__('You have insufficient permissions.'))
      return
    end

    return if attribute.name != 'engineering_owner' || value.blank?

    selected_user = User.find_by(id: value) if value.to_s.match?(%r{\A[1-9]\d*\z})
    return if selected_user&.active? && selected_user.id != 1 && selected_user.permissions?('ticket.agent')

    invalid_because_attribute(__('contains invalid option: %{option}'), option: value)
  end
end
