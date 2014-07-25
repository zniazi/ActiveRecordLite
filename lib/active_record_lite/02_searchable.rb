require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # Cat.where(:name => "Haskell", :color => "calico")
    where_line = params.keys.map { |param| "#{param} = ?"}.join(" AND ")
    values = params.values
    select_sql = <<-SQL
      SELECT
        *
      FROM
        '#{self.table_name}'
      WHERE
        #{where_line}
    SQL

    self.parse_all(DBConnection.execute(select_sql, *values))
  end
end

class SQLObject
  extend Searchable
end
