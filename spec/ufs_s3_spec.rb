require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'UFS::FS' do
  before :all do
    @config_path          = File.join( File.expand_path(File.dirname(__FILE__)), 'fixtures', 's3.yml' )
    UFS.default_adapter  = UFS::S3
    @bn                   = 'test_ufs'
    # The UFS::S3.config method only needs params if the Amazon environment variables are not set
    UFS::FS::File.exists?(@config_path) ? UFS::S3.config = @config_path : @config_path = false
  end
  before :each do
    UFS.disconnect!
  end
  after :each do
    UFS.disconnect!
  end
  
  it 'should instantize' do
    UFS.new.class.should == UFS::S3
  end
  
  it 'should connect to S3 and disconnect' do
    # with bad connection info
    (lambda {UFS::S3.connect!({:access_key_id=>"boo-hoo", :secret_access_key=>"ThisTestShouldFail"})}).should raise_error(UFS::ConnectionError)
        
    if @config_path || !ENV['AMAZON_SECRET_ACCESS_KEY'].nil?
      # Test :connect! without using the preset config using class methods
      UFS.connected?.should be_false
      UFS.connect!(@config_path)
      UFS.connected?.should be_true
      
      UFS.disconnect!.should be_true
      UFS.connected?.should be_false
      
      # Test :connect! using preset config
      UFS.config = @config_path
      s3 = UFS.connect!
      s3.connected?.should be_true
      s3.disconnect!.should be_true
      s3.connected?.should be_false
    else
      s3 = mock('UFS::S3', {
        'connected?'    => UFS::S3.public_methods.include?('connected?'),
        'connect!'      => UFS::S3.public_methods.include?('connect!') ? UFS::S3.new : false,
        'disconnect!'  => UFS::S3.public_methods.include?('disconnect!') ? true : false
      })
      s3.connect!(@config_path).should be_true
      s3.disconnect!.should be_true
    end
  end
  
  it 'should be able to set the UFS::S3.bucket=(bucket_name)' do
    if @config_path || !ENV['AMAZON_SECRET_ACCESS_KEY'].nil?
      UFS.config = @config_path
      UFS.connect!
      name = "#{`whoami`.chomp}-UFS-Test".downcase
      lambda {AWS::S3::Bucket.find(name)}.should raise_error
      UFS.bucket = name
      bucket = AWS::S3::Bucket.find(name)
      bucket.to_s.should == name
      Marshal.dump(bucket).should == Marshal.dump(UFS.bucket)
      AWS::S3::Bucket.current_bucket.should == name
      UFS.bucket.delete.should be_true
    else
      pending('Please configure spec/fixtures/s3.yml and uncomment the @config_path variable above')
    end
  end  
end