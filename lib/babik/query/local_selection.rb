# frozen_string_literal: true

require_relative 'selection'

class LocalSelection < Selection

  attr_reader :model, :selection_path, :selected_field, :operator, :value, :sql_operator, :sql_value

  def initialize(model, selection_path, value)
    super
    @selected_field, @operator = @selection_path.to_s.split(OPERATOR_SEPARATOR)
    _initialize_sql_operator
    _initialize_sql_value
  end

  def sql_where_condition
    "#{@model.table_name}.#{@selected_field} #{@sql_operator} #{@sql_value}"
  end

end