require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'FSDS' do
  after :each do
    FSDS.default_adapter(nil) # reset because: Class variables presist between tests...
  end
  
  it 'should be able to add class & instance methods to objects inheriting from FSDS through :add_class_method & :add_instance_method' do
    class TestAddingClassMethods < FSDS; end
    
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
    FSDS.default_adapter.should be_nil
    # Set and default_adapter
    FSDS.default_adapter=(FSDS).should be_true
    # Read default_adapter
    FSDS.default_adapter.should == FSDS
    
    # Set the default_adapter without the :default_adapter= method... also test resetting it to nil
    FSDS.default_adapter(nil).should be_nil
    # Read default_adapter
    FSDS.default_adapter.should be_nil
  end
  
  it 'instantization should give you an instance of the default adapter or FSDS if no default_adapter is set' do
    FSDS.should === FSDS.new
    if defined?(FSDS::FS)
      FSDS.default_adapter=(FSDS::FS)
      FSDS::FS.should === FSDS.new
      
      # The following ensures that the attributes are passed through.  Although it makes some 
      # assumptions about the object being tested which *should* be outside the scope of this test
      FSDS.new('/tmp').path.should == '/tmp'  
    end
    
    if defined?(FSDS::S3)
      FSDS.default_adapter=(FSDS::S3)
      FSDS::S3.should === FSDS.new
    end
  end
  
  it 'instantization of an inherited object should not be affected by the default_adapter setting' do
    FSDS::FS::File.should == FSDS::FS::File
    FSDS::FS::File.new.class.should == FSDS::FS::File
    FSDS.default_adapter=(FSDS::FS)
    FSDS::FS::File.should == FSDS::FS::File
    FSDS::FS::File.new.class.should == FSDS::FS::File
  end
end
