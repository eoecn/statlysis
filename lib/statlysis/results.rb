# encoding: utf-8

module Statlysis
  class Results
    attr_accessor :data
    # 1, inline
    # 2, collection
    def initialize data
      self.data = data
      self
    end

    def output
      self.data.to_a
    end
  end
end
