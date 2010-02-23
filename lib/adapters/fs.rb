require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'ufs') unless defined?(UFS)

class UFS::FS < UFS
  attr_accessor :permissions, :owner, :group
  
  # Retuns a UFS adapter instance (File System Object).  The path, permissions, ownership & group can be 
  # specified as attributes. The filesystem is not touched by this method.  The methods that 
  # make changes to the filesystem are generally ending with an exclamation point (!) and the 
  # methods that read from the filesystem are generally ending with a question mark (?).  If an instance of UFS::FS
  # is given as the path then that instance is returned.
  #
  # Examples:
  #   UFS::FS::Dir.new '/tmp/test'
  #   UFS::FS::Dir.new '/tmp/test', 755
  #   UFS::FS::Dir.new '/tmp/test', 755, 'joshaven'
  #   UFS::FS::Dir.new '/tmp/test', 755, 'joshaven', 'staff'
  #   UFS::FS::Dir.new '/tmp/test', nil, 'joshaven'          # The attributes are ordered, however they are ignored if nil.
  #
  #   dir = UFS::FS::Dir.new '/tmp/test'
  #   UFS::FS::Dir.new(dir).path == dir.path                 #=> true
  def initialize(pth=nil, priv=nil, own=nil, grp=nil)
    # duplicat instance if initilize is called with an instance as the first argument
    if pth.is_a?(UFS::FS::File) || pth.is_a?(UFS::FS::Dir)
      priv  = pth.permissions
      own   = pth.owner
      grp   = pth.group
      pth   = pth.path
    end
    self.path        = ::File.expand_path(pth) unless pth.nil?
    self.permissions = priv unless priv.nil?
    self.owner       = own unless own.nil?
    self.group       = grp unless grp.nil?
  end
  
  def path
    # This ensures that path is never nil, which upsets some ::File or ::Dir methods
    @path ||= ''
  end
  
  # Compares the given path string with the associated UFS path string. Returns true or false.
  #
  # Example:
  #   UFS.new('/tmp') == '/tmp'  #=> true
  def ==(string)
    self.path == string
  end
  
  # Returns the path of the file.  To read the content of a text file, See: :read or :readln
  # 
  # Example:
  #   f = UFS.touch '/tmp/deleteme'
  #   f.to_s                          #=> "/tmp/deleteme"
  def to_s
    path
  end
  
  # Returns a hash of information on the UFS.  This method is dependent upon a Posix environment!
  #
  # Keys:
  # :name, :permissions, :owner, :group, :size, :modified, :mkdird, :subordinates  (subordinates are number of items contained)
  def proprieties
    begin
      looking_for = (self.is_a?(Dir) ? '.' : path)
      file = ::File.new(path)
      `ls -alT #{path}`.split("\n").collect { |line| # itterate through each line of the ls results looking for our record
        i = line.split(' ')
        return {
          :name         => i[9],
          :permissions  => permissions_as_fixnum(i[0]), #sprintf("%o", File.stat(path).mode)[- 3..-1].to_i, 
          :subordinates => i[1].to_i,  # Number of subordant object... directory contains at least: (. & ..), file contains 1: its self
          :owner        => i[2],
          :group        => i[3],
          :size         => i[4].to_i,
          :modified     => file.mtime, # 5-8 will be time but its easier to use the File object to retrieve the modified & mkdird times
          :created      => file.ctime 
        } if looking_for == i[9] || Regexp.new("#{path} ->") === "#{i[9]} #{i[10]}"
      }.compact
    rescue
      {}
    end
    return {}
  end
  
  # Get or set the permissions properity of a UFS Ruby object.  This does not change or query anything in the filesystem.  
  # To make changes to the filesystem, call the :permissions! method.
  # To query the filesystem call the :permissions? method.
  def permissions(arg=nil)
    arg.nil? ? @permissions : @permissions = arg.to_s
  end
  alias_method :permissions=, :permissions
  
  # Returns an integer representation of the permissions or nil if SFO doesn't exist.
  #
  # Example: 
  #   UFS('/tmp').permissions?   # => 777
  def permissions?
    proprieties[:permissions]
  end
  
  # Sets the file or dir permissions if the UFS adapter object & permissions are valid.
  # Returns false if given invalid permissions or directory is not in existence.
  # The Permissions can be set via arguments or via the :permissions method.
  #
  # - arg: optional permission to set, can be inferred from the permissions instance variable if set.
  # - options: optional hash with a sudo and/or arguments keys: p.destroy!({:sudo => 'superSecret', :arguments => '-R'})
  #
  # FIXME:  This is not cross platform, it relys on chmod & posix permissions
  def permissions!(arg=permissions, options={})
    options, arg = arg, options if arg.is_a? Hash     # Swap arguments if arguments seem to be backward
    arg = permissions if Hash == arg               # in the event that only options are given

    return false unless arg.is_a?(Fixnum) && /[0-7]{3}/ === arg.to_s # validate arg
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
  
  # Get or set the owner properity of a UFS Ruby object.  This does not change or query anything in the filesystem.  
  # To make changes to the filesystem, call the :owner! method.
  # To query the filesystem call the :group? method.
  #
  # Examples:
  #   UFS.mkdir('/tmp/testing.txt')
  #   UFS.owner 'joshaven'      #=> 'joshaven'
  #   UFS.owner                 #=> 'joshaven' 
  def owner(arg=nil)
    arg.nil? ? @owner : @owner = arg.to_s
  end
  alias_method :owner=, :owner
  
  # Returns the current owner of the UFS or nil if it doesn't exitst.  This reads from the filesystem
  #
  # Examples:
  #   p = UFS.mkdir '/tmp/my_test'   # => #<UFS:0x10062dfd0 @permissions=nil, @path="/tmp/my_test", @group=nil>
  #   p.owner?                        # => "joshaven"  # or what ever your username is
  #   p.destroy!                      # => true        # just a bit of cleanup
  def owner?
    # exists? ? `ls -al #{path} | grep '[0-9] \.$'`.split[2] : false
    proprieties[:owner]
  end
  
  # Sets the current owner of the UFS.  Returns true or false.
  #
  # options: options must be a hash with two optional keys:  :sudo & :arguments
  # * sudo: (optional) your sudo password
  # * arguments: (optional) string containing valid chown options, ie: '-R' for recursive
  #
  # Examples:
  #   p = UFS.mkdir '/tmp/my_test'  #
  #   p.owner 'root'
  #   # The following will issue the command `sudo chown -R root /tmp/my_test` and supplies the password
  #   p.owner! {:sudo => 'mySecretPassword', :arguments => '-R'}  
  #
  # FIXME:  This is not cross platform, it relys on chown
  def owner!(arg=owner, options={})
    options, arg = arg, options if arg.is_a?(Hash) && !arg.empty?  # Swap arguments if arguments seem to be backward
    arg = owner if arg.is_a? Hash
    
    return false unless arg.is_a? String                          # validate arg
    owner = arg
    
    return false if owner.nil? || !(options.is_a? Hash)
    system_to_boolean "#{'echo '+options[:sudo]+'|sudo -S ' if options.has_key?(:sudo)}chown #{options[:arguments]} #{owner} #{path}" unless path.nil? || owner.nil?
  end
  
  # Get or set the group properity of a UFS Ruby object.  This does not change or query anything in the filesystem.  
  # To make changes to the filesystem, call the :owner! method.
  # To query the filesystem call the :group? method.
  def group(arg=nil)
    arg.nil? ? @group : @group = arg.to_s
  end
  alias_method :group=, :group
  
  
  # Returns the current group of the filesystem object or nil if it doesn't exitst.  This reads from the filesystem.
  #
  # Examples:
  #   UFS.group? '/tmp'    #=> "wheel"
  def group?
    proprieties[:group]
  end

  # Sets the current group of the UFS.  Returns true or false.
  #
  # grp_name: optional group name as a string.  If not provided, the group setter will use the value of the @group 
  # instance variable.
  #
  # options: options must be a hash with two optional keys:  :sudo & :arguments
  # - sudo: (optional) your sudo password
  # - arguments: (optional) string containing valid chown options, ie: '-R' for recursive
  #
  # Examples:
  #   p = UFS.mkdir '/tmp/my_test'
  #   p.owner 'root'
  #   # The following will issue the command `sudo chown -R root /tmp/my_test` and supplies the password
  #   p.owner! {:sudo => 'mySecretPassword', :arguments => '-R'}
  #
  # FIXME:  This is not cross platform, it relys on chmod & posix permissions
  def group!(arg=group, options={})
    options, arg = arg, options if arg.is_a?(Hash) && !arg.empty?  # Swap arguments if arguments seem to be backward
    arg = group if arg.is_a? Hash                                 # in the event that only options are given
    
    return false unless arg.is_a? String                          # validate arg
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

  # Removes UFS from filesystem, returning true if successful or false if unsuccessful.
  #
  # Options:
  # * options may contain a hash with a sudo key containing a password: p.destroy!({:sudo => 'superSecret'})
  #
  # Example:
  # p = UFS.touch('/tmp/deleteme')
  # p.destroy!                          # => true
  # p.destroy!                          # => false    # its already gone, but the UFS object remains.
  # p.destroy! :sudo => 'superSecret'   # => false    # This does delete as super user, but its still not there
  # UFS.destroy!('/tmp/not_here_123')  # => false    # This assumes that you have set UFS.default_adapter
  def destroy!(options={})
    begin
      if options.has_key? :sudo
        system_to_boolean "echo #{options[:sudo]}| sudo -S rm -r #{path}"
      else
        system_to_boolean "rm -r #{path}"
      end
    rescue
      false
    end
  end

  # Move file or directory from current location to given location
  #
  # Examples:
  #   f = UFS::FS::File.touch '/tmp/deleteme.txt'
  #   f.move '~'                                      # Moves the file 'f' to the home dir and returns self
  #   f.path                                          #=> "/home/username/deleteme.txt"   # this is relitive to your path... '~'
  def move(new_location, options={})
    if new_location.is_a? String
      new_location = ::File.expand_path(new_location) + ::File::Separator
      raise UFS::WriteError if ::File.exists?(new_location + name)
      begin
        raise UFS::IOError unless system_to_boolean(
          options.has_key?(:sudo) ? "echo #{options[:sudo]}| sudo -S mv #{path} #{new_location}" : "mv #{path} #{new_location}"
        ) && self.path=(new_location + name)
      rescue
        raise UFS::IOError
      end
    else
      raise "The first paramater must be a String representation of the path to the new location."
    end
    return self
  end

  def self.method_missing(sym, *args, &block)
    if UFS::FS::File.public_methods.include?(sym.to_s)
      UFS::FS::File.send(sym, *args, &block) unless UFS::FS::Dir.public_methods.include?(sym.to_s)
    elsif UFS::FS::Dir.public_methods.include?(sym.to_s)
      UFS::FS::Dir.send(sym, *args, &block)
    else
      super
    end
  end

private
  # This returns true or false when evaluating a system command.
  def system_to_boolean(str)
    "0\n" == `#{str} >& /dev/null; echo $?`
  end
  
  # converts permissions as a string to octal format... for example: -rwxr-xr-x will become: 755
  def permissions_as_fixnum(permissions_string)
    permissions_string.slice(1..9).gsub('--x','1').gsub('-w-','2').gsub('-rx','3').gsub('r--','4').gsub('r-x','5').gsub('rw-','6').gsub('rwx','7').to_i
  end
end

# Require supporting files:  everything in ./fs/*.rb
Dir.glob(File.join(File.expand_path(__FILE__).split('.').first, '*.rb')).each {|path| require path }
