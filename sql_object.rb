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


end
