# frozen_string_literal: true

json.partial! "pass", locals: {pass: @pass}
json.call @pass, :destroyed?
