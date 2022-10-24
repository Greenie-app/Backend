# frozen_string_literal: true

# `extend` a model with this module to add {#set_nil_if_blank}.

module SetNilIfBlank

  # @overload set_nil_if_blank(field, ...)
  #   Specifies that the given field(s) should be set to nil if their values are
  #   `#blank?`.
  #   @param [Symbol] field The name of a field to set nil if blank.

  def set_nil_if_blank(*fields)
    fields.each do |field|
      before_validation { |obj| obj.send :"#{field}=", nil if obj.send(field).blank? }
    end
  end
end
