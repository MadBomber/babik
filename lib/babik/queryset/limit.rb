# frozen_string_literal: true

require 'babik/query/select_related_association'

module Babik
  module QuerySet
    # Manages the limit of the QuerySet
    class Limit
      attr_reader :size, :offset

      # Construct a limit for QuerySet
      # @param size [Integer] Size to be selected
      # @param offset [Integer] Offset from the selection will begin. By default is 0.
      def initialize(size, offset = 0)
        @size = size.to_i
        @offset = offset.to_i
      end

    end
  end
end


