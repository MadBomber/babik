# frozen_string_literal: true

module Babik
  module QuerySet
    # Sort functionality of QuerySet
    module Sortable

      # Sort QuerySet according to an order
      # @param order [Array, String, Hash] ordering that will be applied to the QuerySet.
      # @return [QuerySet] reference to this QuerySet.
      def order_by(*order)
        @_order = Babik::QuerySet::Order.new(@model, *order)
        self
      end

      # Alias for order_by
      # @see #order_by
      # @param order [Array, String, Hash] ordering that will be applied to the QuerySet.
      # @return [QuerySet] reference to this QuerySet.
      def order(*order)
        order_by(*order)
      end

      # Invert the order
      # e.g.
      #   first_name ASC, last_name ASC, created_at DESC => invert => first_name DESC, last_name DESC, created_at ASC
      # @return [QuerySet] reference to this QuerySet.
      def invert_order
        @_order.invert!
        self
      end
    end
  end
end