require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'FSDS::FS::File' do
  before :all do
    @fn = '/tmp/deleteme.txt'
    # @sudo_password = 'SetMe'
  end
  before :each do
    @file = FSDS::FS::File.new @fn
  end
  
  after :each do
    @file.destroy!
  end
  
  it 'should instantize' do
    FSDS::FS.should be_true
    FSDS::FS::File.should === FSDS::FS::File.new
  end
  
  it 'should be able to touch' do
    FSDS::FS::File.should === FSDS::FS::File.touch(@fn)
    FSDS::FS::File.should === @file.touch
  end
  
  it 'should answer exists?' do
    @file.exists?.should be_false
    @file.touch
    @file.exists?.should be_true
  end
  
  it 'should be able to destroy!' do
    @file.touch @fn
    @file.exists?.should be_true
    @file.destroy!.should be_true
    @file.destroy!.should be_false
    @file.exists?.should be_false
  end
  
  it 'should respond to :type, ==, & ===' do
    @file.type.should == FSDS::FS::File
    FSDS::FS::File.should === @file
    @file.should == @fn
  end
  
  it "should respond to proprieties" do
    @file.touch @fn
    @file.proprieties[:group].should =~ /wheel|root/
  end
  
  it 'should handle :permissions permissions? permissions!' do
    passwd = FSDS::FS::File.new('/etc/passwd')
    passwd.permissions?.should === 644
    
    f = FSDS::FS::File.touch '~/deleteme.txt'
    Integer.should === f.permissions?
    f.permissions?.should_not == 777
    f.permissions!(777).should be_true
    f.permissions?.should == 777
    f.destroy!.should be_true
  end
  
  it 'should handle :owner, :owner?, & :owner!' do
    my_user_name = `whoami`.chomp
    
    @file.touch @fn
    @file.owner?.should == my_user_name
    if @sudo_password
      @file.owner!('root', {:sudo=> @sudo_password}).should be_true
      @file.owner?.should == 'root'
      @file.destroy!({:sudo=> @sudo_password}).should be_true
    end
  end
  
  it "should handle :group, :group?, & :group!" do
    @file.touch
    @file.group?.should =~ /wheel|root/
    @file.group!('everyone').should be_true
    @file.group?.should == 'everyone'
  end
  
  it 'should be able to read & write files' do
    @file.touch
    @file.concat 'First'
    @file << ' test!'
    @file.read.should == "First test!"
    @file << "\nSecond line."
    @file.read.should == "First test!\nSecond line."
  end
  
  it 'should return self when writing to a file or raise an error' do
    FSDS::FS::File.should === @file.concat!('Hello')
    FSDS::FS::File.should === (@file << ' world')
    @file.destroy!.should be_true
    (lambda { @file << 'hello' }).should raise_error(FSDS::IOError)
  end
  
  it 'should write by line' do
    @file.touch
    @file.writeln "First"
    @file.writeln("Second").should be_true
    @file.read.should == "First\nSecond\n"
  end
  
  it 'should read lines by number' do
    @file.touch
    (0..4).to_a.each {|i| @file.writeln "Line: #{i}"}
    @file.readln(0).should == "Line: 0"
    @file.readln(4).should == "Line: 4"
    # There are only lines 0 through 4... line 5 is non-existant and so returns nil.
    @file.readln(5).should be_nil
  end
  
  it 'should read lines by range' do
    @file.touch
    (0..3).to_a.each {|i| @file.writeln "Line: #{i}"}
    @file.readln((0..2)).should == ["Line: 0", "Line: 1", "Line: 2"]
    # Should not go beyond the limits of the file... the following is equal to read: 
    #   beginning at the third line through the next hundred lines...
    @file.readln((2..100)).should == ["Line: 2", "Line: 3"]
  end
  
  it 'should be able to break out of the FSDS::FS::File proxy and access ::File methods' do
    pending {
      @file.touch
      @file.executable?.should be_false
      @file.permissions! 777
      @file.executable?.should be_true
    }
  end
end