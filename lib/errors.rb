# This module contains UFS error deffinations.
# This module is included in the UFS class and thus avilable to all objects that inherit from it.
module UFS_Errors
  # Generic input/output error.  This should be raised when the filesystem access 
  # does not work but the direction is not obvious fromt he context.
  class IOError < Exception; end

  # This should be reaised when the filesystem cannot be read from
  class ReadError < IOError; end
  
  # This should be reaised when the filesystem cannot be written to.
  class WriteError < IOError; end
  
  # This should be raised when the filesystem cannot be connected to
  class ConnectionError < IOError;end
  
  # This should be raised when access is denied to the filesystem or filesystem object
  class PermissionsError < IOError;end
end