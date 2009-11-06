require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::S3::Bucket' do
  before :all do
    # @config_path = File.join( File.expand_path(File.dirname(__FILE__)), 'fixtures', 's3.yml' )
    @config_path = false unless FSDS::FS::File.exists? @config_path
  end
  before :each do
    @s3 =  FSDS::S3.new
  end
  # after :each do
  # end
  
  it 'should instantize' do
    FSDS::S3::Bucket.new.class.should == FSDS::S3::Bucket
  end
  
  it 'should respond to bucket class methods like: mkdir' do
    if @config_path
##########################################################################
# TODO: I stopped here... I have not tested making the 'a' dir on S3 yet #
##########################################################################
      @s3.connect!
      FSDS::S3.mkdir('a').class.should == FSDS::S3::Bucket
      @s3.to_a.should == ['a']
    else
      s3 = mock('FSDS::S3', {
        'connect!'      => FSDS::S3.public_methods.include?('connect!') ? FSDS::S3::Bucket.new : false,
        'mkdir'         => FSDS::S3.public_methods.include?('mkdir') ? FSDS::S3::Bucket.new : false,
        'disconnect!'   => FSDS::S3.public_methods.include?('disconnect!') ? true : false
      })
      s3.mkdir('a').class.should == FSDS::S3::Bucket
    end
  end
end