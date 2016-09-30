require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @cols if @cols

    cols = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.to_s.table_name}
    SQL

    cols.map! { |attribute| attribute.to_sym }
    @cols = cols
  end

  def self.finalize!

    columns.each do |col_name|
      define_method(col_name) do
        attribute_value(col_name)
      end

      define_method("#{col_name}=") do |value|
        set_attribute(col_name, value)
      end
    end

  end

  def self.table_name=(table_name)
    self.instance_variable_set("@#{table_name}", table_name)
  end

  def self.table_name
    table_name = "#{self.name.downcase}s"
    instance_variable_get("@#{table_name}")
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.to_s.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |args| self.new(args) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.to_s.table_name}
      WHERE id = #{id}
      LIMIT 1
    SQL

    values = result.last
    values.nil? ? nil : self.new(result.last)
  end

  def initialize(params = {})
    self.attributes
    self.class.finalize!

    params.each do |param|
      param_sym = param.first.to_sym
      param_name = param.first
      param_val = param.last
      raise "unknown attribute 'favorite_band'" unless self.class.columns.include?(param_sym)
      self.send("#{param_name}=", param_val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def set_attribute(col_name, value)
    attributes
    @attributes[col_name] = value
  end

  def attribute_value(name)
    @attributes[name]
  end

  def attribute_values
    @attributes.values
  end

  def insert
    table_name = "#{self.class.to_s.downcase}s"
    cols = self.class.columns.join(", ")
    values = self.attributes.drop(1).map { |data| "#{data.first}: #{data.last}" }.join(', ')
    # puts "the values are #{values}"
    values_empty = ["?", "?"].join(", ")

    DBConnection.execute(<<-SQL, values)
    INSERT INTO
      #{table_name} (#{cols})
    VALUES
      (#{values_empty})
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update
    # ...
  end

  def save
    # ...
  end
end

class String
  def table_name
    "#{self.downcase}s"
  end
end
