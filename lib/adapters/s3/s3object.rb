# TODO remove every_method(options) sillyness... Its nice, maybe even nessassary to handle specifying a bucket for an action
# but there has to be a better way then always supporting an options hash... maybe only class methods need this feature 
# but with dynamic class methods, most instance methods may need this.

require File.join(File.expand_path(File.dirname(__FILE__)), '..', 's3') unless defined?(UFS::S3)

class UFS::S3::S3Object < UFS::S3
  # Writes data (string or IO stream) to the file, creating the file if it does not exist.
  # options may override either of: (:bucket_name, :content_type)
  def concat!(data, options = {:bucket_name => UFS::S3.bucket.to_s})
    # ::AWS::S3::S3Object.store path, data, options.delete(:bucket_name), options
    begin
      write( (read(options) + data), options)
    rescue UFS::ReadError
      write(data, options)
    end
    self
  end
  
  # Writes data (string or IO stream) to the file or returns UFS::WriteError if the file
  # does not exist.  Options may override either of: (:bucket_name, :content_type)
  def concat(data, options = {:bucket_name => UFS::S3.bucket.to_s})
    raise UFS::WriteError unless exists?
    concat! data, options
  end
  alias_method :<<, :concat
  
  # Ensures file exists by writing an empty string to the file if it doesn't exist.  This
  # is not nessassary for S3 operation but is emplemented for inter-operability with other
  # data stores, primarly POSIX file systems.
  def touch(options = {:bucket_name => UFS::S3.bucket.to_s})
    exists?(options) ? self : concat!('', options)
  end
  
  # Permanently deletes the record on S3 and removes from memory
  def destroy!(options = {:bucket_name => UFS::S3.bucket.to_s})
    return true unless exists?(options)
    
    begin
      vassal.delete && !refresh!
    rescue AWS::S3::NoSuchKey
      true
    end
  end
  
  # Returns True/False
  def exists?(options = {:bucket_name => UFS::S3.bucket.to_s})
    return false if path.nil?
    
    unless UFS::S3.connected? && options[:bucket_name].is_a?(String)
      raise UFS::ConnectionError
    end
    
    return begin
      refresh!(options)
      vassal.is_a?(::AWS::S3::S3Object) && vassal.stored?
    rescue AWS::S3::NoSuchKey
      false
    end
  end
  
  # Returns the entire file as a string.
  #
  # Example:
  #   f = UFS.new 'path/to/file'
  #   f.read   #=> "Line: 0\nLine: 1\n"  
  def read(options = {:bucket_name => UFS::S3.bucket.to_s})
    s3 = vassal(options)
    if s3 && s3.stored?
      s3.value
    else
      raise UFS::ReadError
    end
  end
  
  # Returns a line as a String or a range of lines as an Array.  Given a 10 line file, the first line would be 0 and 
  # the last line would be 9. Represented as a range this would be: file.readln(0..9)
  # 
  # Examples:
  #   f = UFS.new 'path/to/file'
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
      raise UFS::ReadError
    end
  end
  
  
  # Writes a string with an appended newline to to a file.
  #
  # Example:
  #   f = UFS.new 'path/to/file'
  #   f.writeln "Line: 0"
  #   f.writeln "Line: 1"
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def write(data, options = {:bucket_name => UFS::S3.bucket.to_s})
    s3 = initiate(options)
    s3.value = data
    if s3.store
      refresh!
      true
    else
      raise UFS::WriteError
    end
  end
  
  # Writes a string with an appended newline to to a file.
  #
  # Example:
  #   f = UFS.new 'path/to/file'
  #   f.writeln "Line: 0"
  #   f.writeln "Line: 1"
  #   f.read   #=> "Line: 0\nLine: 1\n"
  def writeln(data, options = {:bucket_name => UFS::S3.bucket.to_s})
    # Ensure that the last character in the file is a newline, or that the file is empty
    data = $/ + data unless read_by_bytes(-1) == $/ if size > 0
    concat! data.to_s.chomp + $/
  end
  
  # Move file or directory from current location to given location
  #
  # Examples:
  #   f = UFS::S3::S3Object.touch '/tmp/deleteme.txt'
  #   f.move '~'                                      # Moves the file 'f' to the home dir and returns self
  #   f.path                                          #=> "/home/username/deleteme.txt"   # this is relitive to your path... '~'
  def move(new_location, options={})
    raise "The first paramater must be a String representation of the path to the new location." unless new_location.is_a? String
    
    new_location = as_path(new_location, name) unless new_location.split(::File::Separator).last == name
    raise UFS::WriteError if ::File.exists?(new_location)
    begin
      vassal(options).key = as_path(new_location)
      self.path = vassal.key
    rescue
      raise UFS::IOError
    end
    
    self
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
  #   file = UFS::FS::File.touch '/tmp/deleteme.txt'
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
    # start, finish = start.first, start.last if start.is_a? Range ‰
    start, length = start.first, start.last-start.first+1 if start.is_a? Range
    raise 'start must be an Integer or a Range.' unless start.is_a?(Integer)
    raise 'finish must be an Integer or nil' unless length.is_a?(Integer) || length.is_a?(NilClass)
    s = size
    length = s-start if length.nil? || length > s
    raise 'start byte is beyond the size of the file' if start.abs > s
    read[start, length]
  end
  
  def size
    exists? ? read.size : 0
  end
  
private
  # Returns the S3Object from the AWS store or false if it cannot be found.  Same as calling :proxy but attempts to find
  # the S3Object if it doesn't exist 
  # TODO: consider renaming :vassal to :find
  def vassal(options = {:bucket_name => UFS::S3.bucket.to_s})
    begin
      proxy do
        ::AWS::S3::S3Object.find(path.to_s.gsub(/^\//,''), options[:bucket_name].to_s)
      end
    rescue AWS::S3::NoSuchKey, NoMethodError
      false
    end
  end
  
  # Ensure that the proxied object is fresh from AWS...  If the proxied object doesn't exist on AWS then
  # the proxied object will be set to nil.
  def refresh!(options = {:bucket_name => UFS::S3.bucket.to_s})
    begin
      proxy :force do
        ::AWS::S3::S3Object.find(path.to_s.gsub(/^\//,''), options[:bucket_name].to_s)
      end
    rescue AWS::S3::NoSuchKey, NoMethodError
      proxy nil, :force
      vassal
    end
  end
  
  # Returns a S3Object from the AWS store or a new S3Object.  If a block is given then the block is
  # run before the S3Object is returned.
  # 
  # Example:
  #   initiate              #=> returns a new S3Object or looks up the object given the path object
  #   
  #   data = "Hello World!"
  #   initiate(options) do |s3|
  #     s3.value = data           # This stores the data variable as the content of the S3Object
  #     s3.store                  # This writes the S3 Object to the AWS::S3 store
  #   end
  def initiate(options = {:bucket_name => UFS::S3.bucket.to_s}, &block)
    proxy(vassal(options) || new_s3object(path.to_s.gsub(/^\//,'')), :force)
    unless block.nil?
      yield proxy
    end
    
    proxy
  end
  
  # Returns a new S3Object with the given key name and given or implied bucket.
  # The key must be a string or support the .to_s method
  # The bucket is optional as long as the defult bucket has been set.
  # If a bucket is supplied it must be a AWS::S3::Bucket not the name of a bucket.
  def new_s3object(key, bucket = UFS::S3.bucket)
    s3 = ::AWS::S3::S3Object.new
    s3.key = key.to_s
    s3.bucket = bucket
    s3
  end
end


# Proxy instance methods as class methods
[ 'create!', 'mkdir!', 'mkdir', 'to_a', 'exists?', 'move', 'group', 'group!', 'group?', 'owner', 'touch',
  'owner!', 'owner?', 'destroy!', 'permissions', 'permissions!', 'permissions?'].each do |meth|
  UFS::S3::S3Object.add_class_method meth do |*args, &block|
    self.new(*args).send meth, &block
  end
end

# Register class methods with UFS::FS
['touch', 'create!', 'concat!', 'concat', '<<', 'size', 'exists?'].each do |meth|
  UFS::S3.register_downline_public_methods(meth, UFS::S3::S3Object)
end