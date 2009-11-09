require 'rubygems'
require 'aws/s3'
require 'yaml'

require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'fsds') unless defined?(FSDS)

class FSDS::S3 < FSDS
  attr_accessor :path, :permissions, :owner, :group
  cattr_accessor :config
  
  def initialize(pth=nil, priv=nil, own=nil, grp=nil)
    # duplicat instance if initilize is called with an instance as the first argument
    if FSDS::S3::S3Object === pth
      priv  = pth.permissions
      own   = pth.owner
      grp   = pth.group
      pth   = pth.path
    end
    self.path        = pth unless pth.nil?
    self.permissions = priv unless priv.nil?
    self.owner       = own unless own.nil?
    self.group       = grp unless grp.nil?
  end
  
  # Set the bucket that the 'filesystem' lives in and returns a bucket.  This could be thought of as
  # something like setting your home directory.  Every S3Object must be in a bucket but buckets cannot 
  # contain other buckets so buckets are not like directories.  A single S3 account can have many 
  # buckets but buckets must be unique on Amazon S3.  If the bucket doesn't exist this method will 
  # attempt to create this bucket.
  #
  # Example:
  #   FSDS::S3.bucket = 'something_unique'   # This will set your current bucket to 'something_unique'
  #   AWS::S3::Bucket.current_bucket
  def self.bucket=(name)
    return @bucket if @bucket.to_s == name
    
    begin
      # ::AWS::S3::Service.buckets(true).collect {|b| b if b.instance_variable_get('@attributes')['name'] == name}.compact.first
      @bucket = begin
        ::AWS::S3::Bucket.find name
      rescue
        ::AWS::S3::Bucket.create(name)
        ::AWS::S3::Bucket.find name
      end
      AWS::S3::Bucket.set_current_bucket_to name
    rescue
      unless connected?
        connect!
        untried = untried ? raise(FSDS::ConnectionError) : true
        retry
      end
    end
    raise FSDS::ConnectionError unless ::AWS::S3::Bucket.current_bucket == name
    return @bucket
  end
  def self.bucket
    @bucket
  end
  
  # Setup the authentication information for the Amazon S3 connection.  Accepts a path via a string.
  #
  # Example:
  #   FSDS::S3.config = File.join(APP_ROOT, 'config', 's3.yml')
  # def self.config(file = :notset)
  #   @connection_configuration = file unless file == :notset
  #   @connection_configuration ||= nil
  # end
  
  # Establishes a connection to Amazon S3 or raises FSDS::ReadError.  The read error will indicate
  # that either the config_file is invalid either in format or in content, which is most likely,
  # or that the AWS::S3 connection failed even when given valid content.
  #
  # Example:
  #   FSDS.default_adapter = FSDS::S3
  #   FSDS.config File.join(APP_ROOT, 'config', 's3.yml')
  #   FSDS.connect!
  #   # or by sending a Hash
  #   FSDS::S3.connect! {:access_key_id => "abc", :secret_access_key => "123"}
  #   # or by sending a path
  #   FSDS::S3.connect! File.join(APP_ROOT, 'config', 's3.yml')
  def connect!(credentials = FSDS::S3.config)
    unless connected?
      begin
        FSDS::S3.establish_connection!(Hash == credentials ? credentials : YAML::load(FSDS::FS.read(credentials)))
      rescue; raise FSDS::ConnectionError; end
    end
    self
  end
  
  # Returns true or raises FSDS::IOError
  def disconnect!
    begin
      ::AWS::S3::Base.disconnect!
    rescue; raise FSDS::IOError; end
  end

private
  def acl_to_integer(permissions)
    # default: {owner => self, group => s3_users, everyone => all}
    {
    :private => 600,            # - Owner gets FULL_CONTROL. No one else has any access rights. This is the default.
    :public_read => 604,        # - Owner gets FULL_CONTROL and the anonymous principal is granted READ access. If this policy is used on an object, it can be read from a browser with no authentication.
    :public_read_write => 606,  # - Owner gets FULL_CONTROL, the anonymous principal is granted READ and WRITE access. This is a useful policy to apply to a bucket, if you intend for any anonymous user to PUT objects into the bucket.
    :authenticated_read => 640  # - Owner gets FULL_CONTROL, and any principal authenticated as a registered Amazon S3 user is granted READ access.
    }
  end

end

# Proxy instance methods as class methods
['connect!', 'disconnect!'].each do |meth|
  FSDS::S3.add_class_method meth do |*args, &block|
    self.new.send meth, *args, &block
  end
end

# Proxy ::AWS::S3::Base class methods as class methods
::AWS::S3::Base.public_methods(false).each do |meth|
  FSDS::S3.add_class_method meth do |*args, &block|
    begin
      ::AWS::S3::Base.send meth, *args, &block
    rescue AWS::S3::NoConnectionEstablished
      if FSDS::S3.connect!
        retry
      else
        raise FSDS::ConnectionError
      end
    end
  end
end

# Proxy ::AWS::S3::Base class methods as instance methods
::AWS::S3::Base.public_methods(false).each do |meth|
  case meth
  # when ()
  when *["connection", "connections", "connected?", "current_bucket", "disconnect!"]
    FSDS::S3.add_instance_method meth do
      ::AWS::S3::Base.send meth
    end
  # when (verb, path, options, body, attempts, &block)
  when *["request"]
    FSDS::S3.add_instance_method meth do |*args, &block|
      ::AWS::S3::Base.send meth, *args, &block
    end
  # when (path, headers = {}, body = nil, &block)
  when *["get", "post", "put" "delete", "head"]
    FSDS::S3.add_instance_method meth do |*args, &block|
      ::AWS::S3::Base.send meth, *args, &block
    end
  # when (path!(bucket, key, options), options)
  when *["delete"]
    FSDS::S3.add_instance_method meth do |*args|
      ::AWS::S3::Base.send meth, *args
    end
  # when (*args)
  when *["disconnect", "set_current_bucket_to", "current_bucket=", "connections=", "delete"]
    FSDS::S3.add_instance_method meth do |*args|
      ::AWS::S3::Base.send meth, *args
    end
  end
end

# Require supporting files:  everything in ./s3/*.rb
Dir.glob(File.join(File.expand_path(__FILE__).split('.').first, '*.rb')).each {|path| require path}