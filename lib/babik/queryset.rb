# frozen_string_literal: true

require_relative 'query/conjunction'
require_relative 'query/local_selection'
require_relative 'query/foreign_selection'

# Represents a new type of query result set
class QuerySet
  include Enumerable
  attr_reader :model, :is_count, :has_distinct, :limit, :offset, :order, :lock_type, :filters

  def initialize(model_class)
    @model = model_class
    @is_count = false
    @has_distinct = false
    @limit = nil
    @offset = nil
    @order = nil
    @order_selections = []
    @lock_type = nil
    @other_models = []
    @filters = []
  end

  # Select the objects according to some criteria.
  def filter(filters)
    if filters.class == Array
      disjunctions = filters.map do |filter|
        Conjunction.new(@model, filter)
      end
      @filters << disjunctions
    elsif filters.class == Hash
      @filters << Conjunction.new(@model, filters)
    end
    self
  end

  def all
    @model.find_by_sql(self.sql)
  end

  def each(&block)
    self.all.each(&block)
  end

  def get
    @model.find_by_sql(self.sql).first
  end

  def empty?
    self.count.zero?
  end

  def exists?
    self.count.positive?
  end

  def length
    self.count
  end

  def count
    @is_count = true
    sql_ = _render_select_sql
    ActiveRecord::Base.connection.execute(sql_)[0]['number_of_rows']
  end

  def distinct
    @has_distinct = true
    self
  end

  def order_by(*order_by_list)
    @order = order_by_list
    @order_selections = []
    @order.each_with_index do |order_field, order_field_index|
      order_path = order_field[0]
      @order_selections << Selection.factory(model, order_path, 'xx')
    end
    self
  end

  def lock
    @lock_type = 'FOR UPDATE'
    self
  end

  def [](param)
    if param.class == Range
      _limit(limit: param.min, offset: param.max.to_i - param.min.to_i)
    elsif param.class == Integer
      _limit(limit: param, offset: 0)
    else
      raise "Invalid limit passed to query: #{param}"
    end
    self
  end

  def _limit(limit: nil, offset: nil)
    @offset = offset.to_i
    @limit = limit.to_i
    self
  end

  def sql
    _render_select_sql
  end

  def _sql_left_joins
    left_joins_by_alias = {}
    @filters.flatten.each do |conjunction|
      left_joins_by_alias.merge!(conjunction.left_joins_by_alias)
    end
    # FIXME: order selection should be a class with common parts with selection
    @order_selections.each do |order_selection|
      left_joins_by_alias.merge!(order_selection.left_joins_by_alias)
    end
    left_joins_by_alias.values.map(&:sql).join("\n")
  end

  def _render_select_sql
    self._render_sql("#{__dir__}/templates/default/select/main.sql.erb")
  end

  def _render_sql(template_path)
    template_content = File.read(template_path)
    ERB.new(template_content).result_with_hash(queryset: self)
  end

end