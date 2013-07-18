# encoding: UTF-8

require 'active_record'

__END__
def ActiveRecord.[] regexp
  raise "#{regexp} should be a Regexp!" if not regexp.is_a?(Regexp)
end
