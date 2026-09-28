# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Ticket::Priority.create_if_not_exists(
  id: 1,
  name: __('Low')
)

Ticket::Priority.create_if_not_exists(
  id: 2,
  name: __('Medium'),
  default_create: true
)

Ticket::Priority.create_if_not_exists(
  id: 3,
  name: __('High'),
  ui_icon: 'important',
  ui_color: 'high-priority'
)

Ticket::Priority.create_if_not_exists(
  id: 4,
  name: __('Critical'),
  ui_icon: 'important',
  ui_color: 'high-priority'
)