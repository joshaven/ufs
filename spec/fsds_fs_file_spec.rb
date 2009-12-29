require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::FS::File' do
  before :all do
    @fn = '/tmp/deleteme.txt'
    @app_root = File.expand_path( File.join(File.dirname(__FILE__), '..') )

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
    FSDS::FS::File.new.is_a?(FSDS::FS::File).should be_true
  end

  it 'should not blow up when the path is blank' do
    FSDS::FS::File.exists?(nil).should be_false
  end
  
  it 'should instantize when given an instance' do
    FSDS::FS::File.new(@file).path.should == @file.path
  end
  
  it 'should be able to touch' do
    FSDS::FS::File.touch(@fn).is_a?(FSDS::FS::File).should be_true
    @file.touch.is_a?(FSDS::FS::File).should be_true
    @file.exists?.should be_true
  end
  
  it 'should answer exists?' do
    @file.exists?.should be_false
    @file.touch
    @file.exists?.should be_true
    FSDS::FS::File.exists?(@fn).should be_true
  end
  
  it 'should be able to destroy!' do
    @file.touch @fn
    @file.exists?.should be_true
    @file.destroy!.should be_true
    @file.destroy!.should be_false
    @file.exists?.should be_false
  end
  
  it 'should respond to :class, ==, & ===' do
    @file.class.should == FSDS::FS::File
    FSDS::FS::File.should === @file
    @file.should == @fn
  end
  
  it "should respond to proprieties" do
    @file.touch @fn
    @file.proprieties[:name         ].should == "/tmp/deleteme.txt"
    @file.proprieties[:permissions  ].should == 644                   # The default permissions may be different on different machines
    @file.proprieties[:subordinates ].should == 1                     # self is the only containce of this because its a file
    @file.proprieties[:owner        ].should == `whoami`.chomp        # I owen it cause I made it... Which is why God has the right to define sin and its consiquence.
    @file.proprieties[:group        ].should =~ /wheel|root/          # root on some machines and wheel on others
    @file.proprieties[:size         ].should == 0                     # Its empty, if infact it was just created.
    @file.proprieties[:modified     ].class.should == Time            # The modified time
    @file.proprieties[:created      ].class.should == Time            # The created time
    @file.proprieties[:modified].should == @file.proprieties[:created]
  end
  
  it 'should handle :permissions permissions? permissions!' do
    passwd = FSDS::FS::File.new('/etc/passwd')
    passwd.permissions?.should == 644
    
    f = FSDS::FS::File.touch '~/deleteme.txt'
    f.permissions?.is_a?(Integer).should be_true
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
    @file.concat!('Hello').is_a?(FSDS::FS::File).should be_true
    (@file << ' world').is_a?(FSDS::FS::File).should be_true
    @file.destroy!.should be_true
    (lambda { @file << 'hello' }).should raise_error(FSDS::WriteError)
  end
  
  it 'should write by line' do
    @file.touch
    @file.writeln "First"
    @file.writeln("Second").should be_true
    @file.read.should == "First\nSecond\n"
    
    # should also make sure that writeln doesn't append the prior line...
    @file.destroy!
    @file.touch
    @file << 'First'
    @file.writeln("Second")
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
  
  it 'should :read_by_byte start, finish' do
    @file.touch
    @file << '0123456789'
    # read given only a starting point
    @file.read_by_bytes(0).should == '0123456789'
    @file.read_by_bytes(1).should == '123456789'
    # read given a start byte the number of bytes to finish at
    @file.read_by_bytes(2,2).should == '23'
    # read given a negitive number (back from the end)
    @file.read_by_bytes(-2).should == '89'
    @file.read_by_bytes(-3, 1).should == '7'
    # read given a range
    @file.read_by_bytes(1..3).should == '123'
    
    @file.destroy!
    @file.touch
    @file << "0123456789\n123\n"
    @file.read_by_bytes(-1).should == "\n"
    @file.read_by_bytes(-4).should == "123\n"
    
    # test beyond file limits error handeling
    lambda {@file.read_by_bytes(16)}.should raise_error
    lambda {@file.read_by_bytes(-16)}.should raise_error
    lambda {@file.read_by_bytes(0, 100)}.should_not raise_error
  end
  
  it 'should be able to move' do
    @file.destroy!("~/#{@fn}")
    @file.touch.should be_true
    @file.move('~').is_a?(FSDS::FS::File).should be_true
    @file.path.should == File.expand_path("~/#{@file.name}")
    @file.destroy!.should be_true
  end
  
  it 'should port ::File class methods' do
    @file.touch
    @file.executable?.should be_false
    @file.permissions! 777
    @file.executable?.should be_true
    
    FSDS::FS::File.new.join('tmp', 'test').should == ::File.join('tmp', 'test')
    FSDS::FS::File.join('tmp', 'test').should == ::File.join('tmp', 'test')
  end
  
  it 'should port ::File instance methods' do
    @file.touch
    @file.atime.should == ::File.new(@fn).atime
  end
  
  it 'should port some instance methods to class methods' do
    bin_file  = File.join( @app_root, 'spec', 'fixtures', 'copycat.jpg' )
    text_file = File.join( @app_root, 'spec', 'spec_helper.rb' )
    
    FSDS::FS::File.read(bin_file).should == FSDS::FS::File.new(bin_file).read
    FSDS::FS::File.exists?(text_file).should be_true
  end
  
  it 'should be able to handle binary files' do
    FSDS.default_adapter = FSDS::FS
    spec_path = File.expand_path(File.dirname(__FILE__))
    fixture_path = FSDS::FS::File.join(spec_path, 'fixtures')
    pic = FSDS::FS::File.new("#{spec_path}/fixtures/copycat.jpg")
    pic.move(spec_path).path.should == FSDS::FS::File.join(spec_path, 'copycat.jpg')
    pic.move(fixture_path).path.should == FSDS::FS::File.join(fixture_path, 'copycat.jpg')
    (14000...16000).should === pic.size
  end
end