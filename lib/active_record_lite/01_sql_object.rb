require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    columns_with_data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        '#{self.table_name}'
    SQL

    columns = columns_with_data.first.map { |col| col.to_sym }
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) { self.attributes[column] }
      define_method("#{column}=".to_sym) do |new_value|
        self.attributes[column] = new_value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    select_sql = <<-SQL
      SELECT
        *
      FROM
        '#{self.table_name}'
    SQL

    self.parse_all(DBConnection.execute(select_sql))
  end

  def self.parse_all(results)
    results.map { |hash| self.new(hash) }
  end

  def self.find(id)
    obj_select = <<-SQL
      SELECT
        '#{self.table_name}'.*
      FROM
        '#{self.table_name}'
      WHERE
        '#{self.table_name}'.id = ?
    SQL

    self.parse_all(DBConnection.execute(obj_select, id)).first
  end

  def attributes
    @attributes
  end

  def insert
    insert_sql = <<-SQL
      INSERT INTO
        '#{self.class.table_name}' (#{self.class.columns.join(', ')})
      VALUES
        (#{(["?"] * self.class.columns.length).join(', ')})
    SQL

    inserted_columns = DBConnection.execute(insert_sql, *self.attribute_values)
    self.id = DBConnection.last_insert_row_id
    inserted_columns
  end

  def initialize(params = {})
    @attributes = {}
    params.each do |attr_name, attr_value|
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=".to_sym, attr_value)
    end
  end

  def save
    self.id ? self.update : self.insert
  end

  def update
    update_sql = <<-SQL
      UPDATE
        '#{self.class.table_name}'
      SET
        #{self.class.columns.map { |attr_val| "#{attr_val} = ?"}.join(', ')}
      WHERE
        id = ?
    SQL

    DBConnection.execute(update_sql, *self.attribute_values, self.id)
  end

  def attribute_values
    self.class.columns.map { |col| self.send(col) }
  end
end










