require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'FSDS' do
  before :all do
    # Enable the following and set your password to test things that require sudo
    # @sudo_passwd = 'SuperSecret'
    @test_path = '/tmp/deleteme'
  end

  before :each do
    FSDS.destroy! @test_path
  end
  
  # it 'Reminder to remove sudo password from setup block' {pending{fail}}
  
  it 'should instantize' do
    FSDS.new('/tmp').should === Dir
    FSDS('/tmp').should === Dir  # Wow, nice loverly thing!
                                # Thanks to the ability to extend the Kernel without a conflict in naming with constants!
  end
  
  it 'should answer exists?' do
    # test dir
    FSDS.exists?('/tmp/').should be_true
    FSDS.exists?('/tmp/not/here/ever/12345678900987654321/').should be_false
    FSDS.new('/tmp').exists?.should be_true
    FSDS.new('/tmp/not/here/ever/12345678900987654321/').exists?.should be_false
    # test file
    FSDS.touch @test_path
    FSDS.exists?(@test_path).should be_true
  end
  
  it 'should handle :mkdir and :destroy for files or folders' do
    FSDS.exists?(@test_path).should be_false
    p = FSDS.mkdir @test_path   # creates a dir
    p.exists?.should be_true
    FSDS.mkdir(@test_path).should be_true   # dir already exists so mkdir is true
    p.destroy!
    p.exists?.should be_false
  end
  
  it 'should handle :touch' do
    f = FSDS.touch @test_path
    f.should === File
    FSDS.touch(@test_path).should be_true  # You should be able to touch existing files...
    f.destroy!
    
    d = FSDS.mkdir @test_path
    FSDS.touch(@test_path).should be_false
  end
  
  it "should respond to proprieties" do
    # for dir
    d = FSDS.new '/tmp'
    d.proprieties[:group].should =~ /wheel|root/
    # for file
    f = FSDS.touch @test_path
    f.proprieties[:group].should =~ /wheel|root/
  end
  
  it 'should handle :permissions permissions? permissions!' do
    passwd = FSDS.new('/etc/passwd')
    passwd.permissions?.should === 644
    
    # for dir
    d = FSDS.new '/tmp'
    d.permissions.should be_nil
    d.permissions?.should === 755
    Integer.should === d.permissions?
    d = FSDS.new '/tmp/not_real/'
    d.permissions?.should be_nil
    
    # set permissions
    d=FSDS.new('~/delete_me_dir')
    d.destroy!
    d.mkdir
    d.permissions?.should === 755
    d.permissions!(777).should be_true
    d.permissions?.should === 777
    d.destroy!
    d.mkdir
    d.permissions!({:arguments => '-R'}, 777).should be_true  # test swapped attributes
    d.permissions?.should === 777
    d.destroy!
    
    # for file
    f=FSDS.touch '~/deleteme'
    Integer.should === f.permissions?
    f.permissions?.should_not == 777
    f.permissions!(777).should be_true
    f.permissions?.should == 777
    f.destroy!
  end
  
  it 'should handle :owner, :owner?, & :owner!' do
    # for dir
    my_user_name = `whoami`.chomp

    d = FSDS.new @test_path
    d.destroy!
    d.owner?.should be_nil
    d.mkdir
    d.owner?.should == my_user_name
    new_owner = my_user_name
    d.owner new_owner
    d.owner!.should be_true
    d.destroy!.should be_true
    d.destroy!.should be_false
    if @sudo_passwd
      d.mkdir
      new_owner = 'root'
      d.owner new_owner
      d.owner.should == new_owner
      d.owner?.should == my_user_name
      d.owner!( :sudo => @sudo_passwd ).should be_true
      d.owner?.should == new_owner
      d.destroy! :sudo => @sudo_passwd
      d.owner!.should be_false
    end
    
    # for file
    f = FSDS.touch @test_path
    f.owner?.should == my_user_name
    f.destroy!
    if @sudo_password
      f.touch
      f.owner!('root', {:sudo=> @sudo_password}).should be_true
      f.owner?.should == 'root'
      f.destroy!({:sudo=> @sudo_password}).should be_true
    end
  end
  
  it "should handle :group, :group?, & :group!" do
    # for dir
    d = FSDS.new @test_path
    d.destroy! # Ensure we have a clean slate!
    d.mkdir
    d.group.should be_nil
    d.group?.should =~ /wheel|root/
    d.group! 'staff'
    d.group?.should == 'staff'
    # the following cannot be done without superuser, but it works when provided a password
    if @sudo_passwd
      d.group = FSDS.group?('/tmp')
      d.group!('everyone', {:sudo => @sudo_passwd}).should be_true
      d.group?.should == 'everyone'
    end
    d.destroy!.should be_true
    
    # for File
    f = FSDS.new @test_path
    f.destroy!
    f.touch
    f.group?.should =~ /wheel|root/
    
    f.group!('everyone').should be_true
    f.group?.should == 'everyone'
  end
  
  it 'should inherit permissions' do
    d = FSDS.mkdir '/tmp/deleteme/'
    d.group?.should == FSDS.group?('/tmp')
    d.destroy!
    
    f = FSDS.touch @test_path
    f.group?.should == FSDS.group?('/tmp')
  end
  
  it 'should know to_s' do
    p=FSDS.new @test_path
    p.to_s.should == @test_path
  end  
  
  it 'should be able to pass missing methods to the file & dir objects' do
    f = FSDS.touch @test_path
    f.executable?.should == false  # should turn into:  File.executable?(file_name) => true or false
    pending do  
      # need to double check the method_missing instance method of FSDS... some asumptions are being made
      fail
    end
  end
  
  it 'should be able to read & write files' do
    f = FSDS.touch @test_path
    f.concat 'First'
    f << ' test!'
    f.read.should == "First test!"
    f << "\nSecond line."
    f.read.should == "First test!\nSecond line."
  end
  
  it 'should return self when writing to a file or raise an error' do
    lambda { FSDS(@test_path) << 'hello' }.should raise_error(FSDS::IOError)
  end
  
  it 'should write by line' do
    f = FSDS.touch @test_path
    f.writeln "First"
    f.writeln("Second").should be_true
    f.read.should == "First\nSecond\n"
  end
  
  it 'should read lines by number' do
    f = FSDS.touch @test_path
    (0..4).to_a.each {|i| f.writeln "Line: #{i}"}
    f.readln(0).should == "Line: 0"
    f.readln(4).should == "Line: 4"
    # There are only lines 0 through 4... line 5 is non-existant and so returns nil.
    f.readln(5).should be_nil
  end
  
  it 'should read lines by range' do
    f = FSDS.touch @test_path
    (0..3).to_a.each {|i| f.writeln "Line: #{i}"}
    f.readln((0..2)).should == ["Line: 0", "Line: 1", "Line: 2"]
    # Should not go beyond the limits of the file... the following is equal to read: 
    #   beginning at the third line through the next hundred lines...
    f.readln((2..100)).should == ["Line: 2", "Line: 3"]
  end
  
  # it 'should have a FSDS::File class' do
  #   FSDS::File.greet.should == "Hello from FSDS::File"
  # end
end
