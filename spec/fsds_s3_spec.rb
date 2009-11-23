require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::FS' do
  before :all do
    # @config_path = File.join( File.expand_path(File.dirname(__FILE__)), 'fixtures', 's3.yml' )
    @config_path = false unless FSDS::FS::File.exists? @config_path
    
    FSDS.default_adapter(FSDS::S3)
  end
  after :all do
    FSDS.disconnect!
  end
  
  it 'should instantize' do
    FSDS.new.class.should == FSDS::S3
  end
  
  it 'should connect to S3 and disconnect' do

    if @config_path || !ENV['AMAZON_SECRET_ACCESS_KEY'].nil?
      # Test :connect! without using the preset config using class methods
      FSDS.connected?.should be_false
      FSDS.connect!(@config_path)
      FSDS.connected?.should be_true
      
      FSDS.disconnect!.should be_true
      FSDS.connected?.should be_false
      
      # Test :connect! using preset config
      FSDS.config = @config_path
      s3 = FSDS.connect!
      s3.connected?.should be_true
      s3.disconnect!.should be_true
      s3.connected?.should be_false
    else
      s3 = mock('FSDS::S3', {
        'connected?'    => FSDS::S3.public_methods.include?('connected?'),
        'connect!'      => FSDS::S3.public_methods.include?('connect!') ? FSDS::S3.new : false,
        'disconnect!'  => FSDS::S3.public_methods.include?('disconnect!') ? true : false
      })
      s3.connect!(@config_path).should be_true
      s3.disconnect!.should be_true
    end
    # with bad connection info
    (lambda {FSDS::S3.connect!({:access_key_id=>"boo-hoo", :secret_access_key=>"ThisTestShouldFail"})}).should raise_error(FSDS::ConnectionError)
  end
  
  it 'should be able to set the FSDS::S3.bucket=(bucket_name)' do
    if @config_path || !ENV['AMAZON_SECRET_ACCESS_KEY'].nil?
      FSDS.config = @config_path
      FSDS.connect!
      name = "#{`whoami`.chomp}-FSDS-Test".downcase
      lambda {AWS::S3::Bucket.find(name)}.should raise_error
      FSDS.bucket = name
      bucket = AWS::S3::Bucket.find(name)
      bucket.to_s.should == name
      Marshal.dump(bucket).should == Marshal.dump(FSDS.bucket)
      AWS::S3::Bucket.current_bucket.should == name
      FSDS.bucket.delete.should be_true
    else
      pending('Please configure spec/fixtures/s3.yml and uncomment the @config_path variable above')
    end
  end  
end