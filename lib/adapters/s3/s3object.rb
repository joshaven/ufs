require File.join(File.expand_path(File.dirname(__FILE__)), '..', 's3') unless defined?(FSDS::S3)

class FSDS::S3::S3Object < FSDS::S3
  # Writes data (string or IO stream) to the file, creating the file if it does not exist.
  # options may override either of: (:bucket_name, :content_type)
  def concat!(data, options = {:bucket_name => FSDS::S3::bucket.to_s})
    ::AWS::S3::S3Object.store path, data, options.delete(:bucket_name), options
    self
  end
  
  # Writes data (string or IO stream) to the file or returns FSDS::WriteError if the file
  # does not exist.  Options may override either of: (:bucket_name, :content_type)
  def concat(data, options = {:bucket_name => FSDS::S3::bucket.to_s})
    raise FSDS::WriteError unless exists?
    concat! data, options
  end
  alias_method :<<, :concat
  
  # Ensures file exists by writing an empty string to the file if it doesn't exist.  This
  # is not nessassary for S3 operation but is emplemented for inter-operability with other
  # data stores, primarly POSIX file systems.
  def touch(options = {:bucket_name => FSDS::S3::bucket.to_s})
    exists? ? self : concat!('', options)
  end
  
  # Permanently deletes the file
  def destroy!(bucket_name = FSDS::S3::bucket.to_s)
    proxy(::AWS::S3::S3Object.find path, bucket_name).delete
  end
  
  # Returns True/False
  def exists?(bucket_name = FSDS::S3::bucket.to_s)
    return false if path.nil?
    return begin
      proxy(::AWS::S3::S3Object.find path, bucket_name)
    rescue AWS::S3::CurrentBucketNotSpecified
      raise FSDS::ConnectionError
    rescue AWS::S3::NoSuchKey
      false
    rescue AWS::S3::NoConnectionEstablished
      raise FSDS::ConnectionError
    end
  end
  
  # # Sets the path also known to S3 as the key.  The path can be any string.  The key is always 
  # # packed and unpacked using standard URI escaping rules which allows for standard key naming 
  # # regardless of the file system your on.  For example you can have a path of "C:\Documents and Settings\Me\stored passwords.txt"
  # # the colon, spaces and slashes will be converted into valid S3 key characters.
  # def path=(string)
  #   @path = unpacked_path(string)
  # end
  # 
  # def packed_path(string = path)
  #   URI.escape(string, Regexp.new(URI::REGEXP::UNSAFE.to_s + '|:'))
  # end
  # 
  # def unpacked_path(string = path)
  #   URI.unescape string
  # end
  # 
  # # def packed?
  # #   !(Regexp.new(URI::REGEXP::UNSAFE.to_s + '|:') === path)
  # # end
end


# Proxy instance methods as class methods
[ 'create!', 'mkdir!', 'mkdir', 'to_a', 'exists?', 'move', 'group', 'group!', 'group?', 'owner', 'touch',
  'owner!', 'owner?', 'destroy!', 'permissions', 'permissions!', 'permissions?'].each do |meth|
  FSDS::S3::S3Object.add_class_method meth do |*args, &block|
    self.new(*args).send meth, &block
  end
end

# Register class methods with FSDS::FS
['touch', 'create!', 'concat!', 'concat', '<<', 'size', 'exists?'].each do |meth|
  FSDS::S3.register_downline_public_methods(meth, FSDS::S3::S3Object)
end