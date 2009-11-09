require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::S3::Bucket' do
  it "should answer to_s with the value of @attributes['name']" do
    b=AWS::S3::Bucket.new
    b.to_s.should be_nil
    b.instance_variable_set('@attributes', {'name'=>'test'})
    b.to_s.should == 'test'
  end
end