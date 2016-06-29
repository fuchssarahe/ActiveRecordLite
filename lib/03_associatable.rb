require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.to_s.constantize
  end

  def table_name
    model_class.table_name
  end

end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      class_name: name.to_s.camelcase,
      primary_key: :id,
      foreign_key: name.to_s.underscore.concat("_id").to_sym
    }

    final_options = defaults.merge(options)

    final_options.each do |key, value|
      self.send("#{key}=", value)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: name.to_s.camelcase.singularize,
      primary_key: :id,
      foreign_key: self_class_name.to_s.underscore.concat("_id").to_sym
    }

    final_options = defaults.merge(options)

    final_options.each do |key, value|
      self.send("#{key}=", value)
    end
  end
end

module Associatable
  # Phase IIIb

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      output = options
        .model_class
          .where(options.primary_key => self.send(options.foreign_key))
            .first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)
    define_method(name) do
      output = options
        .model_class
          .where(options.foreign_key => self.send(options.primary_key))
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
