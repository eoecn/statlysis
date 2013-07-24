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
      return self
    end

  end

  def Mongoid.[] regexp
    MongoidDataset.new.set_regexp(regexp)
  end

end
