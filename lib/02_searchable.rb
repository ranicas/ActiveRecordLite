require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    condition = params.map { |attr, key| "#{attr} = ?" }.join(" AND ")
    
    objects = DBConnection.execute(<<-SQL, *params.values)
     SELECT
       *
     FROM
      #{ table_name }
     WHERE
      #{ condition }
     SQL

    self.parse_all(objects)
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
