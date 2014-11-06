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
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options.each do |attr, val|
      instance_variable_set("@#{attr}", val)
    end
    
    self.foreign_key ||= (name + "_id").to_sym
    self.class_name ||= name.to_s.singularize.camelcase 
    self.primary_key ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options.each do |attr, val|
      instance_variable_set("@#{attr}", val)
    end
    
    self.foreign_key ||= (self_class_name.underscore + "_id").to_sym
    self.class_name ||= name.to_s.singularize.camelcase 
    self.primary_key ||= :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    
    define_method name do
      foreign_key = options.foreign_key
      model_class = options.model_class
      key_val = send()
      options.model_class.where(options.primary_key => foreign_key).first
    end
  end

  def has_many(name, options = {})
    options = BelongsToOptions.new(name, options)
    foreign_key = options.foreign_key
    model_class = options.model_class
    model_class.where(model_class.primary_key => foreign_key).first
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
  # Mixin Associatable here...
end
