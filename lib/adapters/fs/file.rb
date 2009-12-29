require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'fs') unless defined?(FSDS::FS)

class FSDS::FS::File < FSDS::FS
  # Retuns a FSDS::FS::File (File Object).  The path, permissions, ownership & group can be 
  # specified as attributes. The filesystem is not touched by this method.  The methods that 
  # make changes to the filesystem are generally ending with an exclamation point (!) and the 
  # methods that read from the filesystem are generally ending with a question mark (?).
  #
  # See also :touch
  #
  # Examples:
  #   FSDS::FS::File.new '/tmp/deleteme.txt'
  #   FSDS::FS::File.new '/tmp/deleteme.txt', 755
  #   FSDS::FS::File.new '/tmp/deleteme.txt', 755, 'joshaven'
  #   FSDS::FS::File.new '/tmp/deleteme.txt', 755, 'joshaven', 'staff'
  #   FSDS::FS::File.new '/tmp/deleteme.txt', nil, 'joshaven'     # The attributes are ordered, however they are ignored if nil.

  # Create a file or directory on the filesystem if it doesn't already exist and set permissions, owner,
  # & group if specified. See FSDS::new for full param options.  Returns an FSDS instance.  See also the 
  # shortcut methods: :mkdir & :touch
  #
  # Examples:
  #   p=FSDS.new  '/tmp/deleteme'         # This assumes that you have set: FSDS.default_adapter = FSDS::FS
  #   p.create! :file                     # Returns an instance of: FSDS::FS::File
  #
  #   # The same can be done in one line: # Also assumes that you've set: FSDS.default_adapter = FSDS::FS
  #   FSDS.create! :file, '/tmp/deleteme'
  #
  #   # If you need root access then send it a sudo:
  #   FSDS.create! :file, '/etc/deleteme', {:sudo => 'superSecretPassword'}
  def create!(pth=path, options={})
    ##### TODO:
    # Need to write this lines support code:
    #   pth,options = sort_path_and_options(pth, options)
    #####
    # from:
    options, pth = pth, options if pth.is_a?(Hash)  # Swap arguments if arguments are backwards
    pth = path if pth.is_a?(Hash)
    return false unless pth.is_a?(String)           # validate arg
    path = pth                                      # ensure the path is set
    #####
    
    cmd_prefix = options.has_key?(:sudo) ? "echo #{options[:sudo]}| sudo -S " : ''
    
    # # Depreciate system call to touch in favor of writing nothing to the file through :concat!
    # raise("Could not touch file: #{path}") unless system_to_boolean("#{cmd_prefix} touch #{options[:arguments]} #{path}")
    self.concat! ''
    
    sudo_options = options.has_key?(:sudo) ? {:sudo => options[:sudo]} : {}
    owner! sudo_options
    group! sudo_options
    permissions! sudo_options
    
    return self
  end
  alias_method :touch, :create!
  
  # Returns true or false.
  #
  # Examples:
  #   FSDS.exists?("/tmp")           #=> true
  def exists?
    ::File.file? path
  end
  
  # Returns the file size of the file in bytes.  This method is aliased as bytes
  #
  # Example:
  #   f = FSDS::FS::File.touch '/tmp/deleteme.txt'
  #   f << "123\n"
  #   f.size        # => 4   # Three numbers and a newline character
  #   f.bytes       # => 4   # Three numbers and a newline character
  def size
    exists? ? ::File.size(path) : nil
  end
  alias_method :bytes, :size
  
  # Appends to a file or raises FSDS::IOError.  This method does not do anything with new line characters.  If you
  # want to write a line of text see the :writeln method.  This method will railse FSDS::IOError if fild doesn't exist
  # call :concat! to create the file by writing to it.
  #
  # Example:
  #   f = FSDS::FS.touch '/tmp/deleteme'
  #   f << 'Hello'
  #   f.concat 'World'
  #   f.read                    #=> "HelloWorld"
  def concat(data)
    raise FSDS::WriteError unless exists?
    concat! data
  end
  alias_method :<<, :concat
  
  # Same as concat but will create a file if it doesn't exist instead of raising an error.
  def concat!(data)
    begin
      ::File.open(path, 'a') { |f| f.print data.to_s }
      self
    rescue
      raise FSDS::WriteError
    end
  end
  
  # Return the content of a file from the given start byte continuing for the optional finish bytes.  
  # If finish byte is not given then the return will include the remainder of the file.  If a negitive 
  # start byte is given then the starting point is counted from the end of the file.  Furthermore a range
  # of bytes may be given.  When a range is given the bytes included in the range will be returned.  Thus, 
  # 5..10 is starting with byte 5 finishing five bytes later at byte 10 which is the same as (5,5).
  #
  # Arguments
  #   start - Integer, The byte to begin reading from
  #   length - Interger, The number of bytes to read
  #
  # Examples:
  #   file = FSDS::FS::File.touch '/tmp/deleteme.txt'
  #   file << '0123456789abcdefghij'
  #   file.read_by_bytes(0..9)    #=> "0123456789"
  #   file.read_by_bytes(5..14)   #=> "56789abcde"
  #   file.read_by_bytes(0,10)    #=> "0123456789" # Returns 10 bytes beginning with the 1st byte.
  #   file.read_by_bytes(10,10)   #=> "abcdefghij" # Returns 10 bytes beginning with the 10th byte.
  #   file.read_by_bytes(-10,10)  #=> "abcdefghij" # Returns 10 bytes beginning with the 10th from last byte.
  #   file.read_by_bytes(-10)     #=> "abcdefghij" # Returns returns the remainder of the bytes beginning with the 10th from the last byte.
  #   file << "\n0123456789\n"    # file is now: "0123456789abcdefghij\n0123456789\n"
  #   file.read_by_bytes(-12,10)  # => "\n012345678"
  #   file.read_by_bytes(-1)      # => "\n"
  #   file.read_by_bytes(1000, 1) # => RuntimeError: start byte is beyond the size of the file
  def read_by_bytes(start, length = nil)
    start, length = start.first, start.last-start.first+1 if start.is_a? Range
    
    raise 'start must be an Integer or a Range.' unless start.is_a?(Integer)
    raise 'finish must be an Integer or nil.' unless length.is_a?(Integer) || length.is_a?(NilClass)

    f = proxy :force do
      ::File.new(path)
    end
    
    s = size
    raise FSDS::ReadError if s.nil?
    length = s-start if length.nil? || length > s
    raise 'start byte is beyond the size of the file' if start.abs > s
    f.seek(start, ((start < 0) ? IO::SEEK_END : IO::SEEK_SET) )
    f.read(length)
  end
  
  # Writes a string with an appended newline to to a file.
  #
  # Example:
  #   f = FSDS.new 'path/to/file'
  #   f.writeln "Line: 0"
  #   f.writeln "Line: 1"
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def writeln(data)
    if size > 0
      self.concat "#{$/ unless read_by_bytes(-1) == $/}#{data.to_s.chomp}#{$/}"
    else
      self.concat "#{data.to_s.chomp}#{$/}"
    end
  end

  # Returns the entire file as a string.
  #
  # Example:
  #   f = FSDS.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def read
    begin
      ::File.read(path) # documented in IO class
    rescue
      raise FSDS::ReadError 
    end
  end

  # Returns a line as a String or a range of lines as an Array.  Given a 10 line file, the first line would be 0 and 
  # the last line would be 9. Represented as a range this would be: file.readln(0..9)
  # 
  # Examples:
  #   f = FSDS.new 'path/to/file'
  #   f.readln 0   #=> "Line: 0"
  #   f.readln(0..2)   #=> ["Line: 0", "Line: 1", "Line: 2"]
  def readln(line)
    begin
      if line.is_a? Fixnum
        str = ::File.readlines(path)[line]
        str.is_a?(String) ? str.chomp : str
      elsif line.is_a? Range
        ::File.readlines(path)[line.first, line.last+1].collect {|str| str.chomp if str.is_a?(String) }
      end
    rescue
      raise FSDS::ReadError
    end
  end
end

# proxy instance methods as class methods
[ 'exists?', 'create!', 'touch', 'read', 'size', 'bytes', 'destroy!', 'move', 'group', 'group!', 'group?', 'owner', 'owner!', 'owner?', 'permissions', 'permissions!', 'permissions?'].each do |meth|
  FSDS::FS::File.add_class_method meth do |*args|
    self.new(*args).send(meth)
  end
end

# register class methods with FSDS::FS
['touch', 'create!', "concat!", "concat", "<<", "size"].each do |meth|
  FSDS::FS.register_downline_public_methods(meth, FSDS::FS::File)
end



# The following will make proxy methods to the ::File class if the file class has the 
# proper method.  The various cases are for alternate formats of the paramaters.
# If the method is not referenced in one of the formatting variables then the method will
# not be proxied.  If a ::File method is extended or modified then this feature is
# not affected unless the modifications effect the paramaters of the method.  Also, ::File
# can be extended through including ftools without any changes to the method proxies as 
# long as that module is included prior to the instantation of the FSDS::FS::File object.

# proxy ::File class methods
::File.methods.each do |meth|
  case meth
  # Class proxy: () to ::File class method
  when *["allocate", "pipe"]
    FSDS::FS::File.add_class_method meth do
      ::File.send meth
    end
  # Instance proxy: (path, [arguments]) to ::File class method
  when *["atime", "basename", "blockdev?", "catname", "chardev?", "compare", "copy", "ctime", "delete", "directory?", "dirname", 
         "executable?", "executable_real?", "exist?", "exists?", "expand_path", "extname", "file?", "foreach", "for_fd", "ftype", 
         "grpowned?", "identical?", "install", "link", "lstat", "makedirs", "move", "mtime", "new", "open", "owned?", "pipe?", 
         "readable?", "readable_real?", "readlines", "readlink", "rename", "safe_unlink", "setgid?", "setuid?", "size", "size?", 
         "socket?", "split", "stat", "sticky?", "symlink", "symlink?", "syscopy", "sysopen", "truncate", "unlink", "unlink", 
         "writable?", "writable_real?", "zero?"]
    FSDS::FS::File.add_instance_method meth do |*args|
      ::File.send meth, path, *args
    end
  # Instance proxy: (arguments & path) to ::File class method
  when *["chown", "lchmod", "lchown", "utime"]
    FSDS::FS::File.add_instance_method meth do |*args|
      ::File.send meth, *[args, path].compact
    end
  # Instance proxy: (args.shift, path, *args) to ::File class method
  when *["fnmatch", "fnmatch?"]
    FSDS::FS::File.add_instance_method meth do |*args|
      ::File.send(meth, *[args.shift, path, args].compact)
    end
  # Instance & Class Proxy: (args, [&block]) to ::File class method
  when *["join", "umask", "popen", "select", "read"]
    # Define instance methods
    FSDS::FS::File.add_instance_method meth do |*args, &block|
      ::File.send meth, *args, &block
    end
    # Define class methods (see metaclass.rb for the object extention that made this possible)
    FSDS::FS::File.add_class_method meth do |*args, &block|
      ::File.send meth, args, &block
    end
  end
end

# Instance proxy ::File instance methods:
::File.instance_methods.each do |meth|
  case meth
  # Class proxy: (*args)
  when *["atime", "chmod", "chmod", "chown", "ctime", "flock", "lstat", "mtime", "path", "truncate"]
    FSDS::FS::File.add_class_method meth do |*args|
      proxy(::File.new(path)).send(meth, *args)
    end
  end
end

