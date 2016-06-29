require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    string_params = params.map { |col,value| "#{col} = '#{value}'" }.join(" AND ")
    
    results = DBConnection.execute("SELECT * FROM #{table_name} WHERE #{string_params}")

    result = results.map do |res|
      self.new(res)
    end
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end


# Let's write a module named Searchable which will add the ability to search using ::where. By using extend, we can mix in Searchable to our SQLObject class, adding all the module methods as class methods.
#
# So let's write Searchable#where(params). Here's an example:
#
# haskell_cats = Cat.where(:name => "Haskell", :color => "calico")
# # SELECT
# #   *
# # FROM
# #   cats
# # WHERE
# #   name = ? AND color = ?
# I used a local variable where_line where I mapped the keys of the params to "#{key} = ?" and joined with AND.
#
# To fill in the question marks, I used the values of the params object.
