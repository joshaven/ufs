require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::FS' do
  before :all do
    # @config_path = File.join( File.expand_path(File.dirname(__FILE__)), 'fixtures', 's3.yml' )
    @config_path = false unless FSDS::FS::File.exists? @config_path
  end
  before :each do
    @s3 =  FSDS::S3.new
    # @file = FSDS::S3::File.new @fn
    # @bucket = FSDS::S3::Bucket.new @bn
  end
  # after :each do
  #   @file.destroy! if @file
  #   # @bucket.destroy! if @bucket
  # end
  
  it 'should instantize' do
    FSDS.default_adapter(FSDS::S3).should == FSDS::S3
    FSDS.new.class.should == FSDS::S3
  end
  
  it 'should connect to S3 and disconnect' do
    if @config_path
      # Without using the preset config using class methods
      FSDS::S3.connect!(@config_path).should be_true
      FSDS::S3.disconnect!.should be_true
      # Test :connect! returning an instance that can be disconnected that has a preset config
      FSDS::S3.config = @config_path
      s3 = FSDS::S3.connect!
      s3.should be_true
      s3.disconnect!.should be_true
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
    (lambda {FSDS::S3.connect!({:access_key_id=>"boo-hoo", :secret_access_key=>"ya, right"})}).should raise_error(FSDS::ConnectionError)
  end
  
  # it 'should respond to bucket class methods like: mkdir' do
  #   if @config_path
  #     # @s3.connect!
  #     FSDS::S3.mkdir!('a').class.should == FSDS::S3::Bucket
  #     FSDS::S3.exists?('a').should be_true
  #   end
  # end
end