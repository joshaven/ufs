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

  # Working example to write text to S3... 
  # file = '.'
  #   AWS::S3::S3Object.store(
  #     file,
  #     'Hello world!',
  #     'joshaven',
  #     :content_type => 'text/plain',
  #     :access => :public_read
  #   ) # Returns a responce object
  
  # See ACL:
  # object = AWS::S3::S3Object.find '.'
  # irb(main):060:0> puts object.acl.to_yaml
  # --- !ruby/object:AWS::S3::ACL::Policy 
  # attributes: !map:AWS::S3::Parsing::XmlParser 
  #   access_control_list: 
  #     grant: 
  #     - permission: !str:CoercibleString FULL_CONTROL
  #       grantee: &id001 
  #         xsi:http://www.w3.org/2001/xml_schema_instance:type: !str:CoercibleString CanonicalUser
  #         id: !str:CoercibleString 24303d2e1f3406f5592fffe4386bdf803cf037f4798380621f78723df4481659
  #         display_name: !str:CoercibleString alix
  #     - permission: !str:CoercibleString READ
  #       grantee: &id002 
  #         uri: !str:CoercibleString http://acs.amazonaws.com/groups/global/AllUsers
  #         xsi:http://www.w3.org/2001/xml_schema_instance:type: !str:CoercibleString Group
  # grants: 
  # - !ruby/object:AWS::S3::ACL::Grant 
  #   attributes: 
  #     permission: !str:CoercibleString FULL_CONTROL
  #     grantee: *id001
  #   grantee: !ruby/object:AWS::S3::ACL::Grantee 
  #     attributes: 
  #       uri: 
  #       xsi:http://www.w3.org/2001/xml_schema_instance:type: !str:CoercibleString CanonicalUser
  #       id: !str:CoercibleString 24303d2e1f3406f5592fffe4386bdf803cf037f4798380621f78723df4481659
  #       type: 
  #       display_name: !str:CoercibleString alix
  #       email_address: 
  # - !ruby/object:AWS::S3::ACL::Grant 
  #   attributes: 
  #     permission: !str:CoercibleString READ
  #     grantee: *id002
  #   grantee: !ruby/object:AWS::S3::ACL::Grantee 
  #     attributes: 
  #       uri: !str:CoercibleString http://acs.amazonaws.com/groups/global/AllUsers
  #       xsi:http://www.w3.org/2001/xml_schema_instance:type: !str:CoercibleString Group
  #       id: 
  #       type: 
  #       display_name: 
  #       email_address: 
  # owner: !ruby/object:AWS::S3::Owner 
  #   attributes: 
  #     id: !str:CoercibleString 24303d2e1f3406f5592fffe4386bdf803cf037f4798380621f78723df4481659
  #     display_name: !str:CoercibleString alix
  # => nil


  # it 'should respond to bucket class methods like: mkdir' do
  #   if @config_path
  #     @s3.connect!
  #     FSDS::S3.mkdir('a').class.should == FSDS::S3::Bucket
  #     @s3.to_a.should == ['a']
  #   end
  # end
end