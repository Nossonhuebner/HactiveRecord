require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @primary_key = options[:primary_key] || :id
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @class_name = options[:class_name] || name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @primary_key = options[:primary_key] || :id
    @foreign_key = self_class_name[:foreign_key]
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    relation = BelongsToOptions.new(name, options)

    define_method(name) do
      relation.class_name.constantize.where(relation.primary_key => self.id).first
    end
  end

  def has_many(name, options = {})
    foreign_key = options[:foreign_key] || "#{self.to_s.underscore}_id".to_sym
    relation = HasManyOptions.new(name, {foreign_key: foreign_key}, options)

    define_method(name) do
      relation.class_name.constantize.where(relation.foreign_key => self.id)
    end
  end

class SQLObject
  extend Associatable
end
