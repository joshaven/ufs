# This module contains FSDS error deffinations.
# This module is included in the FSDS class and thus avilable to all objects that inherit from it.
module FSDS_Errors
  # Generic input/output error.  This should be raised when the filesystem access 
  # does not work but the direction is not obvious fromt he context.
  class IOError < Exception; end

  # This should be reaised when the filesystem cannot be read from
  class ReadError < IOError; end
  
  # This should be reaised when the filesystem cannot be written to.
  class WriteError < IOError; end
end