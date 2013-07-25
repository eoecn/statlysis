# encoding: UTF-8

require 'mongoid'

# http://mongoid.org/en/origin/index.html
# Origin provides a DSL to mix in to any object to give it the ability to build MongoDB queries easily. It was extracted from Mongoid in an attempt to allow others to leverage the DSL in their own applications without needing a mapper.
require 'origin'

module Statlysis
  class MongoidDataset < MultipleDataset
    include Origin::Queryable # it overwrite MongoidDataset#initialize, so we can't puts @sources in the parent class MultipleDataset

    def set_regexp regexp
      super

      _collections = Mongoid.default_session.collections.select {|_collection| _collection.name.match(@regexp) }

      # select Mongoid models fron ::Object namespace
      mongoid_models = ::Object.constants.reject {|c| c == :Config }.map do |c|
        c.to_s.constantize rescue nil # NameError: uninitialized constant ClassMethods
      end.compact.select do |c|
        (c.class === Class) &&
        c.respond_to?(:included_modules) &&
        c.included_modules.index(Mongoid::Document)
      end
      _collections.select do |_collection|
        _mongoid_model = mongoid_models.detect {|m| m.collection_name === _collection.name }
        raise "Please define Mongoid model for #{_collection}.collection under ::Object namespace!" if _mongoid_model.nil?
        mongoid_models.delete _mongoid_model
        @sources.add _mongoid_model
      end

      return self
    end

    def set_time_column time_column
      @sources = @sources.map {|s| s.asc(time_column) }
      return self
    end

  end

  def Mongoid.[] regexp
    MongoidDataset.new.set_regexp(regexp)
  end

end
