ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'test/unit'
# gem install redgreen for colored test output
begin require 'redgreen'; rescue LoadError; end
