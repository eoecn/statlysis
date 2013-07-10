# copied from git://github.com/joe1chen/mongoid-mapreduce.git

class Employee
  include Mongoid::Document

  field :name
  field :division
  field :awards, :type => Integer
  field :age, :type => Integer
  field :rooms, :type => Array
  field :active, :type => Boolean

  belongs_to :company
end
