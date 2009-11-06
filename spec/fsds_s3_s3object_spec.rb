require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::S3::S3Object' do
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
    FSDS::S3::S3Object.new.class.should == FSDS::S3::S3Object
  end
  
  # it 'should respond to bucket class methods like: mkdir' do
  #   if @config_path
  #     @s3.connect!
  #     FSDS::S3.mkdir('a').class.should == FSDS::S3::Bucket
  #     @s3.to_a.should == ['a']
  #   end
  # end
end