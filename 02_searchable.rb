require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    raise 'Invalid params' unless params.is_a?(Hash)

    vals = params.values
    fields = params.keys.map do |key|
      "#{key} = ?"
    end.join(" AND ")

    results = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{fields}
    SQL
    results.map { |result| self.new(result)}
  end
end

class SQLObject
  extend Searchable
end
