# frozen_string_literal: true

json.partial! "pilot", locals: {pilot: @pilot}
json.call @pilot, :destroyed?
