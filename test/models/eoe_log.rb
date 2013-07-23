# encoding: UTF-8

class EoeLog
  include Mongoid::Document

  field :ii, :type => Integer, :default => 0 # ip_int, request.remote_ip
  field :do, :type => Integer, :default => 1 # request.domain
  field :fp, :type => String, :default => '' # request.original_fullpath
  field :ui, :type => Integer, :default => 0 # user_id
  field :re, :type => String, :default => '' # refer

  field :t,  :type => DateTime, :default => Statlysis::DateTime1970 # timestamp

  # request.headers['HTTP_USER_AGENT']
  field :br, :type => Integer, :default => 0 # browser name
  field :bv, :type => String, :default => '' # browser version
  field :bo, :type => Integer, :default => 0 # os

  index({t: -1, ui: 1}, {:background => true})
end


# Setup a single log that combined by multiple collections
{'07' => 1..31, '08' => 1..12}.map do |month, day_range|
  day_range.map do |day|
    # define model dynamically
    collection_class_name = "MultipleLog2013#{month}#{day.to_s.rjust(2, '0')}"
    Object.const_set(
      collection_class_name,
      (Class.new do
        include Mongoid::Document
        default_collection_name = collection_class_name.sub("MultipleLog", "multiple_log_")
        field :t, :type => DateTime
        field :url, :type => String
      end)
    )
    collection_class = collection_class_name.constantize
    collection_class.create
  end
end
