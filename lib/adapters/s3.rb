require 'rubygems'
require 'aws/s3'
require 'yaml'

require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'fsds') unless defined?(FSDS)

class FSDS::S3 < FSDS
  attr_accessor :path, :permissions, :owner, :group, :current_connection
  cattr_accessor :config
  
  def initialize(pth=nil, priv=nil, own=nil, grp=nil)
    # duplicat instance if initilize is called with an instance as the first argument
    if FSDS::S3::S3Object === pth || FSDS::S3::Bucket === pth
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
        current_connection = FSDS::S3.establish_connection!(Hash == credentials ? credentials : YAML::load(FSDS::FS.read(credentials)))
      rescue; raise FSDS::ConnectionError; end
    end
    self
  end

  # Returns true or false
  def connected?
    ::AWS::S3::Base === current_connection ? current_connection.connected? : false
  end
  
  # Returns true or raises FSDS::IOError
  def disconnect!
    begin
      ::AWS::S3::Base === current_connection ? current_connection.disconnect! : true
    rescue; raise FSDS::IOError; end
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

# Require supporting files:  everything in ./s3/*.rb
Dir.glob(File.join(File.expand_path(__FILE__).split('.').first, '*.rb')).each {|path| require path}