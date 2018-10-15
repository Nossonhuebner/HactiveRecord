require_relative 'db_connection'
require 'byebug'
require 'active_support/inflector' #formats 'ClassName' to 'class_names'

class SQLObject
  def self.columns
    unless @columns
      query = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
      LIMIT
        1
      SQL
      @columns = query[0].map(&:to_sym)
    end
    @columns
  end

  def self.table_name=(table_name)
    @table_name = table_name.tableize
  end

  def self.table_name
    self.table_name = self.to_s unless @table_name
    @table_name
  end

  def initialize(params = {})
    raise "Invalid params" unless params.is_a?(Hash)
    params.keys.each do |attr|
      unless self.class.columns.include?(attr.to_sym)
        raise "unknown attribute '#{attr}'"
      end
      self.send("#{attr}=".to_sym, params[attr])
    end
  end


  #must be called manually after each subclass definition
  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column] }

      define_method("#{column}=") do |val|
         attributes[column] = val
       end
    end
  end
end
