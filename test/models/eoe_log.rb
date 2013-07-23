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
