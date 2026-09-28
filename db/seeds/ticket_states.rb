# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Ticket::State.create_if_not_exists(
  id:             1,
  name:           __('New'),
  state_type_id:  Ticket::StateType.find_by(name: 'new').id,
  default_create: true,
)

Ticket::State.create_if_not_exists(
  id:                2,
  name:              __('Triaged'),
  state_type_id:     Ticket::StateType.find_by(name: 'open').id,
  default_follow_up: true,
)

Ticket::State.create_if_not_exists(
  id:            3,
  name:          __('In progress'),
  state_type_id: Ticket::StateType.find_by(name: 'open').id,
)

Ticket::State.create_if_not_exists(
  id:                4,
  name:              __('Waiting for client'),
  state_type_id:     Ticket::StateType.find_by(name: 'pending reminder').id,
  ignore_escalation: true,
)

Ticket::State.create_if_not_exists(
  id:            5,
  name:          __('Planned'),
  state_type_id: Ticket::StateType.find_by(name: 'open').id,
)

Ticket::State.create_if_not_exists(
  id:            6,
  name:          __('In QA'),
  state_type_id: Ticket::StateType.find_by(name: 'open').id,
)

Ticket::State.create_if_not_exists(
  id:            7,
  name:          __('Resolved'),
  state_type_id: Ticket::StateType.find_by(name: 'open').id,
)

Ticket::State.create_if_not_exists(
  id:                8,
  name:              __('Closed'),
  state_type_id:     Ticket::StateType.find_by(name: 'closed').id,
  ignore_escalation: true,
  default_close:     true,
)