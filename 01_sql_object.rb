require_relative 'db_connection'
require 'byebug'
require 'active_support/inflector' #formats 'ClassName' to 'class_names'

class SQLObject
  def self.columns
    unless @columns
      # ::execute2 returns column names as first element
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

  def self.all
    all_query = DBConnection.execute(<<-SQL )
    SELECT
      *
    FROM
      "#{table_name}"
    SQL
    parse_all(all_query)
  end

  def self.parse_all(results)
    arr = []
    results.each do |result_hash|
      arr.push(self.new(result_hash))
    end
    arr
  end

  def self.find(id)
    query = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{table_name}"
      WHERE
        id = ?
    SQL

    return parse_all(query)[0] if query
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

  def initialize(params = {})
    raise "Invalid params" unless params.is_a?(Hash)

    params.keys.each do |attr|
      unless self.class.columns.include?(attr.to_sym)
        raise "unknown attribute '#{attr}'"
      end
      self.send("#{attr}=".to_sym, params[attr])
    end
  end

  def attributes
    @attributes ||= {}
  end

  def save
    self.id.nil? ? insert : update
  end


  private

  def attribute_values
    attrs = attributes.keys
    vals = attrs.map do |val|
      self.send(val)
    end
    attrs = attrs.map(&:to_s).join(", ")
    [attrs, vals]
  end

  def insert
    attrs, vals = attribute_values
    question_marks = ('?' * vals.length ).split("").join(", ")
    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{self.class.table_name} (#{attrs})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    attrs, vals = attribute_values
    attributes = attrs.split(', ').map do |attr|
      "#{attr} = ?"
    end.join(', ')
    DBConnection.execute(<<-SQL, *vals, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{attributes}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end
end
