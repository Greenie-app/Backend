# frozen_string_literal: true

# Action Cable channel for transmitting changes to {Logfile} records.

class LogfilesChannel < ApplicationCable::Channel

  # @private
  def subscribed = stream_for current_squadron, coder: nil

  # @private
  module Coder
    extend self

    # @private
    def encode(logfile)
      ApplicationController.render(partial: "logfiles/logfile", locals: {logfile:})
    end
  end
end
