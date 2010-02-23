require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'UFS' do
  after :each do
    UFS.default_adapter(nil) # reset because: Class variables presist between tests...
  end
  
  it 'should be able to add class & instance methods to objects inheriting from UFS through :add_class_method & :add_instance_method' do
    class TestAddingClassMethods < UFS; end
    
    TestAddingClassMethods.add_class_method :greet do
      return 'hello from class method'
    end
    
    TestAddingClassMethods.add_instance_method :greet do
      return 'hello from instance method'
    end
    
    TestAddingClassMethods.greet.should == 'hello from class method'
    TestAddingClassMethods.new.greet.should == 'hello from instance method'
  end
  
  it 'should be able to get and set the default_adapter' do
    UFS.default_adapter.should be_nil
    # Set and default_adapter
    (UFS.default_adapter=UFS).should be_true
    # Read default_adapter
    UFS.default_adapter.should == UFS
    
    # Set the default_adapter without the :default_adapter= method... also test resetting it to nil
    UFS.default_adapter(nil).should be_nil
    # Read default_adapter
    UFS.default_adapter.should be_nil
  end
  
  it 'instantization should give you an instance of the default adapter or UFS if no default_adapter is set' do
    UFS.new.is_a?(UFS).should be_true
    if defined?(UFS::FS)
      UFS.default_adapter=(UFS::FS)
      UFS::FS.new.is_a?(UFS).should be_true
      
      # The following ensures that the attributes are passed through.  Although it makes some 
      # assumptions about the object being tested which *should* be outside the scope of this test
      UFS.new('/tmp').path.should == '/tmp'  
    end
    
    if defined?(UFS::S3)
      UFS.default_adapter=(UFS::S3)
      UFS.new.is_a?(UFS::S3).should be_true
    end
  end
  
  it 'instantization of an inherited object should not be affected by the default_adapter setting' do
    UFS::FS::File.should == UFS::FS::File
    UFS::FS::File.new.class.should == UFS::FS::File
    UFS.default_adapter=(UFS::FS)
    UFS::FS::File.should == UFS::FS::File
    UFS::FS::File.new.class.should == UFS::FS::File
  end

  it 'should make paths from path fragments' do
    f = UFS.new
    f.as_path('tmp', '/hello').should == 'tmp/hello'
    f.as_path('tmp', '/hello', {:prefix => '/'}).should == '/tmp/hello'
    f.as_path('tmp', '/hello', {:prefix => '\\'}).should == '/tmp/hello'
    f.as_path('/tmp//hello.txt').should == '/tmp/hello.txt'
    f.as_path('///tmp///hello.txt').should == '/tmp/hello.txt'
    
  end
end
