# frozen_string_literal: true

# @abstract
#
# Abstract superclass for all Greenie.app models.

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
