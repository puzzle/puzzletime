# frozen_string_literal: true

# Worktime#hours= parses "8:45" as well as numbers, so written values must reach the model untouched,
# while reads render the float column as a number.
hours_input = Dry::Types::Nominal.new(Object).constructor { |value| value.is_a?(Numeric) ? value : value.to_s }

Graphiti::Types[:hours] = {
  params: hours_input,
  read: Dry::Types['coercible.float'],
  write: hours_input,
  kind: 'scalar',
  canonical_name: :hours,
  description: 'Hours as a number, or text such as "8:45".'
}
