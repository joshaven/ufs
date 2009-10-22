class FSO
  # require 'adapters/fs/file'
  
  FSO::IOError = "IOError: Cannot communicate with file."
  attr_accessor :path, :permissions, :owner, :group
  # Retuns a FSO (File System Object).  The path, permissions, ownership & group can be 
  # specified as attributes. The filesystem is not touched by this method.  The methods that 
  # make changes to the filesystem are generally ending with an exclamation point (!) and the 
  # methods that read from the filesystem are generally ending with a question mark (?).
  #
  # Examples:
  #   FSO.new '/tmp/test'
  #   FSO.new '/tmp/test', 755
  #   FSO.new '/tmp/test', 755, 'joshaven'
  #   FSO.new '/tmp/test', 755, 'joshaven', 'staff'
  #   FSO.new '/tmp/test', nil, 'joshaven'     # The attributes are ordered, however they are ignored if nil.
  def initialize(dir=nil, priv=nil, own=nil, grp=nil)
    self.path        = File.expand_path(dir) unless dir.nil?
    self.permissions = priv unless priv.nil?
    self.owner       = own unless own.nil?
    self.group       = grp unless grp.nil?
  end

  # Return the type of the FSO.  The answer will be one of: File, Dir, or nil
  def type
    # return File if File.file?(path || '')
    # return Dir if File.directory?(path || '')
    # nil
    File.file?(path || '') ? File : (File.directory?(path || '') ? Dir : nil)
  end

  # Shortcut method to finding the type of a filesystem object without instantizing an FSO.
  #
  # Example:
  #   FSO.type('/tmp')   #=> Dir
  def self.type(*args)
    FSO.new(*args).send(:type)
  end
  
  # Compares the type of the FSO with the given type.  Returns true or false.
  #
  # Example:
  #   FSO.new('/tmp') === Dir  #=> true
  def ===(klass)
    self.type == klass
  end
  
  # Compares the given path string with the associated FSO path string. Returns true or false.
  #
  # Example:
  #   FSO.new('/tmp') == '/tmp'  #=> true
  def ==(string)
    self.path == string
  end
  
  # Create a file or directory on the filesystem if it doesn't already exist and set permissions, owner,
  # & group if specified. See FSO::new for full param options.  They type paramter is required and must be 
  # one of: [:file, :dir].  Returns an FSO instance.  See also the shortcut methods: :mkdir & :touch
  #
  #
  # Examples:
  #   p=FSO.new  '/tmp/deleteme'        # this sets the path that is needed for the next command.
  #   p.create! :file
  #   # OR
  #   FSO.create! :file, '/tmp/deleteme', {:sudo => 'superSecretPassword'}
  #   p.destroy!                        # cleanup sample file!
  def create!(type, pth=path, options={})
    options, pth = pth, options if Hash === pth   # Swap arguments if arguments are backwards
    pth = path if Hash === pth
    
    return false unless String === pth            # validate arg
    path = pth                                    # ensure the path is set
    
    cmd_prefix = options.has_key?(:sudo) ? "echo #{options[:sudo]}| sudo -S " : ''
    my_type = self.type  # minimize access to File.file? & File.directory?
    
    if type == :dir && !(self === Dir)
      return false unless my_type == nil || my_type == File
      raise("Could not touch file: #{path}") unless system_to_boolean("#{cmd_prefix} mkdir #{options[:arguments]} #{path}")
    elsif type == :file
      return false unless my_type == nil || my_type == File
      raise("Could not mkdir directory: #{path}") unless system_to_boolean("#{cmd_prefix} touch #{options[:arguments]} #{path}") 
    else
      # bail with false if trying to make a dir into a file or a file into a dir
      return false if (type == :dir && self == File) || (type == :fie && self == Dir)
    end
    
    sudo_options = options.has_key?(:sudo) ? {:sudo => options[:sudo]} : {}
    self.owner! sudo_options
    self.group! sudo_options
    self.permissions! sudo_options
    
    return self
  end


  
  # Create a Directory on the filesystem if it doesn't already exist.  This is a shortcut to the :create! 
  # method with specifying :dir.  Returns a FSO instance.  See also: create!
  #
  # Examples:
  #   p=FSO.new  '/tmp/deleteme'
  #   p.mkdir
  #   # OR:
  #   p = FSO.mkdir '/tmp/deleteme'
  #   p.destroy!                      # cleanup test dir
  def mkdir(pth=path, options={})
    create! :dir, pth, options
  end
  
  # Create a File on the filesystem if it doesn't already exist.  This is a shortcut to the :create! 
  # method with specifying :file.  Returns a FSO instance.  See also: create!
  #
  # Examples:
  #   p=FSO.new  '/tmp/deleteme'
  #   p.touch
  #   # OR:
  #   p = FSO.touch '/tmp/deleteme'
  #   p.destroy!                      # cleanup test file
  def touch(pth=path, options={})
    create! :file, pth, options
  end
  
  
  # Get or set the owner properity of a FSO Ruby object.  This does not change or query anything in the filesystem.  
  # To make changes to the filesystem, call the :owner! method.
  # To query the filesystem call the :group? method.
  #
  # Examples:
  #   FSO.mkdir('/tmp/testing.txt')
  #   FSO.owner 'joshaven'      #=> 'joshaven'
  #   FSO.owner                 #=> 'joshaven' 
  def owner(arg=nil)
    arg.nil? ? @owner : @owner = arg.to_s
  end
  alias_method :owner=, :owner
  
  # Returns the current owner of the FSO or nil if it doesn't exitst.  This reads from the filesystem
  #
  # Examples:
  #   p = FSO.mkdir '/tmp/my_test'   # => #<FSO:0x10062dfd0 @permissions=nil, @path="/tmp/my_test", @group=nil>
  #   p.owner?                        # => "joshaven"  # or what ever your username is
  #   p.destroy!                      # => true        # just a bit of cleanup
  def owner?
    # exists? ? `ls -al #{path} | grep '[0-9] \.$'`.split[2] : false
    proprieties[:owner]
  end
  
  # Sets the current owner of the FSO.  Returns true or false.
  #
  # options: options must be a hash with two optional keys:  :sudo & :arguments
  # * sudo: (optional) your sudo password
  # * arguments: (optional) string containing valid chown options, ie: '-R' for recursive
  #
  # Examples:
  #   p = FSO.mkdir '/tmp/my_test'  #
  #   p.owner 'root'
  #   # The following will issue the command `sudo chown -R root /tmp/my_test` and supplies the password
  #   p.owner! {:sudo => 'mySecretPassword', :arguments => '-R'}  
  def owner!(arg=owner, options={})
    options, arg = arg, options if Hash === arg && !arg.empty?  # Swap arguments if arguments seem to be backward
    arg = owner if Hash === arg
    
    return false unless String === arg                          # validate arg
    owner = arg
    
    return false if owner.nil? || !(Hash === options)
    system_to_boolean "#{'echo '+options[:sudo]+'|sudo -S ' if options.has_key?(:sudo)}chown #{options[:arguments]} #{owner} #{path}" unless path.nil? || owner.nil?
  end
  
  
  # Get or set the group properity of a FSO Ruby object.  This does not change or query anything in the filesystem.  
  # To make changes to the filesystem, call the :owner! method.
  # To query the filesystem call the :group? method.
  def group(arg=nil)
    arg.nil? ? @group : @group = arg.to_s
  end
  alias_method :group=, :group
  
  
  # Returns the current group of the filesystem object or nil if it doesn't exitst.  This reads from the filesystem.
  #
  # Examples:
  #   FSO.group? '/tmp'    #=> "wheel"
  def group?
    proprieties[:group]
  end

  # Sets the current group of the FSO.  Returns true or false.
  #
  # grp_name: optional group name as a string.  If not provided, the group setter will use the value of the @group 
  # instance variable.
  #
  # options: options must be a hash with two optional keys:  :sudo & :arguments
  # - sudo: (optional) your sudo password
  # - arguments: (optional) string containing valid chown options, ie: '-R' for recursive
  #
  # Examples:
  #   p = FSO.mkdir '/tmp/my_test'
  #   p.owner 'root'
  #   # The following will issue the command `sudo chown -R root /tmp/my_test` and supplies the password
  #   p.owner! {:sudo => 'mySecretPassword', :arguments => '-R'}
  def group!(arg=group, options={})
    options, arg = arg, options if Hash === arg && !arg.empty?  # Swap arguments if arguments seem to be backward
    arg = group if Hash === arg                                 # in the event that only options are given
    
    return false unless String === arg                      # validate arg
    group(arg)
    begin
      if options.has_key? :sudo
        system_to_boolean "echo #{options[:sudo]}| sudo -S chgrp #{options[:arguments]} #{group} #{path}"
      else
        system_to_boolean "chgrp #{options[:arguments]} #{group} #{path}" 
      end
    rescue
      false
    end
  end

  # Get or set the permissions properity of a FSO Ruby object.  This does not change or query anything in the filesystem.  
  # To make changes to the filesystem, call the :permissions! method.
  # To query the filesystem call the :permissions? method.
  def permissions(arg=nil)
    arg.nil? ? @permissions : @permissions = arg.to_s
  end
  alias_method :permissions=, :permissions
  
  # Returns an integer representation of the permissions or nil if SFO doesn't exist.
  #
  # Example: 
  #   FSO('/tmp').permissions?   # => 777
  def permissions?
    proprieties[:permissions]
  end
  
  # Sets the FSO permissions if the FSO & permissions are valid.
  # Returns false if given invalid permissions or directory is not in existence.
  # The Permissions can be set via arguments or via the :permissions method.
  #
  # - arg: optional permission to set, can be inferred from the permissions instance variable if set.
  # - options: optional hash with a sudo and/or arguments keys: p.destroy!({:sudo => 'superSecret', :arguments => '-R'})
  def permissions!(arg=permissions, options={})
    options, arg = arg, options if Hash === arg     # Swap arguments if arguments seem to be backward
    arg = permissions if Hash == arg               # in the event that only options are given

    return false unless Fixnum === arg && /[0-7]{3}/ === arg.to_s # validate arg
    permissions(arg)
    
    unless permissions.nil? || permissions? == permissions  # only proceed if there is something to do
      begin
        if options.has_key? :sudo
          system_to_boolean "echo #{options[:sudo]}| sudo -S chmod #{options[:arguments]} #{permissions} #{path}"
        else
          system_to_boolean "chmod #{options[:arguments]} #{permissions} #{path}" 
        end
      rescue
        false
      end
    end
  end
  
  # Returns true or false.  Shortcut method to: FSO.new('/tmp').type != nil
  #
  # Examples:
  #   FSO.exists?("/tmp")           #=> true
  def exists?
    self.type != nil
  end
  
  # Removes FSO from filesystem, returning true if successful or false if unsuccessful.
  #
  # Options:
  # * options may contain a hash with a sudo key containing a password: p.destroy!({:sudo => 'superSecret'})
  #
  # Example:
  # p = FSO.mkdir('/tmp/text')
  # p.destroy!                          # => true
  # p.destroy!                          # => false    # its already gone, but the FSO object remains.
  # p.destroy! :sudo => 'superSecret'   # => false    # its already gone, but the FSO object remains.
  # FSO.destroy!('/tmp/not_here_123')  # => false    # By the way, the method missing magic works here to.
  def destroy!(options={})
    begin
      if options.has_key? :sudo
        system_to_boolean "echo #{options[:sudo]}| sudo -S rm #{'-r' if self === Dir} #{path}"
      else
        system_to_boolean "rm #{'-r' if self === Dir} #{path}"
      end
    rescue
      false
    end
  end

  # Returns a hash of information on the FSO.  This method is dependent upon a Posix environment!
  #
  # Keys:
  # :name, :permissions, :owner, :group, :size, :modified, :mkdird, :subordinates  (subordinates are number of items contained)
  def proprieties
    begin
      looking_for = (self === Dir ? '.' : path)
      file = File.new(path)
      `ls -ahlT #{path}`.split("\n").collect { |line| # itterate through each line of the ls results looking for our record
        i = line.split(' ')
        return {
          :name         => i[9],
          :permissions  => permissions_as_fixnum(i[0]), #sprintf("%o", File.stat(path).mode)[- 3..-1].to_i, 
          :subordinates => i[1],  # Number of subordant object... directory contains at least: (. & ..), file contains 1: its self
          :owner        => i[2],
          :group        => i[3],
          :size         => i[4],
          :modified     => file.mtime, # 5-8 will be time but its easier to use the File object to retrieve the modified & mkdird times
          :mkdird      => file.ctime 
        } if looking_for == i[9] || Regexp.new("#{path} ->") === "#{i[9]} #{i[10]}"
      }.compact
    rescue
      {}
    end
    return {}
  end


  def concat(data)
    if self === File
      begin
        File.open(path, 'a') { |f| f.print data }
        self
      rescue
        raise FSO::IOError
      end
    else
      raise FSO::IOError
    end
  end
  alias_method :<<, :concat

  # Writes a string with an appended newline to to a file.    
  #
  # Example:
  #   f = FSO.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def writeln(data)
    concat "#{data.chomp}\n"
  end
  
  # Returns the entire file as a string.
  #
  # Example:
  #   f = FSO.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def read
    File.read(path) # documented in IO class
  end

  # Returns a line as a String or a range of lines as an Array.  Given a 10 line file, the first line would be 0 and 
  # the last line would be 9. Represented as a range this would be: file.readln(0..9)
  # 
  # Examples:
  #   f = FSO.new 'path/to/file'
  #   f.readln 0   #=> "Line: 0"
  #   f.readln(0..2)   #=> ["Line: 0", "Line: 1", "Line: 2"]
  def readln(line)
    if Fixnum === line
      str = File.readlines(path)[line]
      String === str ? str.chomp : str
    elsif Range === line
      File.readlines(path)[line.first, line.last+1].collect {|str| str.chomp if String === str}
    end
  end

  def to_s
    path
  end

  # Cute little trick that mkdirs a new instance of FSO given the args and sends it the requested method...
  # 
  # Example:
  #   FSO.mkdir('/tmp/test', 755)  # calls => FSO.new('/tmp/test', 755).mkdir
  def self.method_missing(mth, *args)
    self.new(*args).send(mth)
  end

  # This breaks out of the FSO wrapper and allows access to the standard objects: File, Dir
  def method_missing(mth, *args)
    # this assumes that a path is the standard input... this is not very protected... need to check Dile & Dir API's
    args = [path] if args.empty?
    
    my_type = self.type
    if my_type == File
      File.send(mth, *args) if File.methods.include? mth.to_s
    elsif my_type == Dir
      Dir.send(mth, *args) if Dir.methods.include? mth.to_s
    end
    
  end

private
  def system_to_boolean(str)
    "0\n" == `#{str} >& /dev/null; echo $?`
  end

  def permissions_as_fixnum(permissions_string)
    permissions_string.slice(1..9).gsub('--x','1').gsub('-w-','2').gsub('-rx','3').gsub('r--','4').gsub('r-x','5').gsub('rw-','6').gsub('rwx','7').to_i
  end
end



# make the :new method optional...  appends the Kernel object.

module Kernel
  def FSO(*params)
    ::FSO.new *params
  end
end