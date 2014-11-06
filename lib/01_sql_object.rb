require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    cols[0].map(&:to_sym)  
  end
  
  def self.finalize!
    self.columns.each do |col|
      define_method "#{col}" do
        attributes[col]
      end
      
      define_method "#{col}=" do |val|
        self.attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
   @table_name = table_name
  end

  def self.table_name
    table_name =  self.to_s.tableize 
    @table_name ||= table_name
  end

  def self.all
    objects = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    
    self.parse_all(objects)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    
    self.new(obj[0])
  end

  def initialize(params = {})
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      send("#{attr_name}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |col|
      send("#{col}")
    end
  end

  def insert
    cols = self.class.columns.map(&:to_s).join(", ")
    params = (["?"] * self.class.columns.count).join(", ")
  
   DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{ self.class.table_name } (#{cols})
     VALUES
        (#{params})
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  def update
    update_str = self.class.columns.map do |col|
      "#{col} = ?"
    end.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
    UPDATE
      #{ self.class.table_name }
    SET
     #{ update_str }
    WHERE
      id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
