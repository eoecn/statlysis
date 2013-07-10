# copied from git://github.com/joe1chen/mongoid-mapreduce.git

class Company
  include Mongoid::Document

  field :name, :type =>  String
  field :market, :type =>  String
  field :shares, :type =>  Integer
  field :quote, :type =>  Float

  has_many :employees
end
