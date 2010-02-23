require 'rubygems'
require 'cucumber'
require 'spec/expectations'

# Require main project file
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'ufs'
