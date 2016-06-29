require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns if @columns
    cols = DBConnection.execute2("SELECT * FROM #{table_name} LIMIT 0")
    @columns = cols[0].map {|col| col.to_sym }
  end

  def self.finalize!

    columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    rows = DBConnection.execute("SELECT * FROM #{table_name}")
    parse_all(rows)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    values = DBConnection.execute("SELECT * FROM #{table_name} WHERE id = ? LIMIT 1", id)
    return nil if values.length < 1
    self.new(values.first)
  end

  def initialize(params = {})
    params.each { |key,_| raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym) }
    params.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    values = attributes.values
  end

  def insert
    cols = self.class.columns.map {|att| att.to_s }
    cols.delete('id')
    cols = cols.join(", ")

    values = self.attribute_values.map do |value|
      if value.is_a?(Fixnum)
        value
      else
        "'#{value}'"
      end
    end.join(", ")

    DBConnection.execute("INSERT INTO #{self.class.table_name} (#{cols}) VALUES (#{values})")
    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns.map {|att| att.to_s }
    cols.delete('id')

    values = self.attribute_values.map do |value|
      if value.is_a?(Fixnum)
        value
      else
        "'#{value}'"
      end
    end

    idx = values.shift

    set_string = []
    (0...cols.length).each { |idx| set_string << "#{cols[idx]} = #{values[idx]}"}

    cols = cols.join(", ")
    values = values.join(", ")
    set_string = set_string.join(", ")

    DBConnection.execute("UPDATE #{self.class.table_name} SET #{set_string} WHERE id = #{idx} LIMIT 1")
  end

  def save
    id.nil? ? insert : update
  end
end
