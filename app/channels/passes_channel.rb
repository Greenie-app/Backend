# frozen_string_literal: true

# Action Cable channel for transmitting changes to {Pass} records.

class PassesChannel < ApplicationCable::Channel

  # @private
  def subscribed = stream_for current_squadron, coder: nil

  # @private
  module Coder
    extend self

    # @private
    def encode(pass, unknown_pass_count: nil)
      ApplicationController.render partial: "passes/pass",
                                   locals:  {
                                       pass:,
                                       include_squadron:   true,
                                       unknown_pass_count:
                                   }
    end
  end
end
