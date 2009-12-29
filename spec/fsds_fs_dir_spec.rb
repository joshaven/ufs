require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::FS::Dir' do
  before :all do
    @dn = ::File.join(::File::Separator + 'tmp', 'deleteme')
    # @sudo_password = 'SetMe'
  end
  before :each do
    @dir = FSDS::FS::Dir.new @dn
  end
  after :each do
    @dir.destroy!
  end
  
  it 'should instantize' do
    FSDS::FS::Dir.new.is_a?(FSDS::FS::Dir).should be_true
  end
  
  it 'should be able to mkdir' do
    @dir.mkdir.is_a?(FSDS::FS::Dir).should be_true
    FSDS::FS::Dir.mkdir(@dn).is_a?(FSDS::FS::Dir).should be_true
    lambda {FSDS::FS::Dir.mkdir('/tmp/does_not_exist/deleteme')}.should raise_error(FSDS::WriteError)
  end
  
  it 'should be able to mkdir!' do
    lambda {FSDS::FS::Dir.mkdir('/tmp/deleteme/another').should be_false}.should raise_error(FSDS::WriteError)
    FSDS::FS::Dir.mkdir!('/tmp/deleteme/another').should be_true
    FSDS::FS::Dir.destroy!('/tmp/deleteme/another')
  end
  
  it 'should answer exists?' do
    FSDS::FS::Dir.exists?('/tmp').should be_true
    FSDS::FS::Dir.exists?('/tmp/not/here/ever/12345678900987654321').should be_false
    @dir.exists?.should be_false
    @dir.mkdir
    @dir.exists?.should be_true
  end
  
  it 'should be able to destroy' do
    @dir.mkdir
    @dir.exists?.should be_true
    @dir.destroy!.should be_true
    @dir.exists?.should be_false
    FSDS::FS::Dir.mkdir!('/tmp/deleteme').should be_true
    FSDS::FS::Dir.destroy!('/tmp/deleteme').should be_true
  end
  
  it 'should be able to move' do
    @dir.destroy!("~/#{@dn}")
    @dir.mkdir.should be_true
    @dir.move('~').is_a?(FSDS::FS::Dir).should be_true
    @dir.path.should == File.expand_path("~/#{@dir.name}")
    @dir.destroy!.should be_true
  end
  
  it 'should respond to :to_a' do
    @dir.mkdir
    f1 = FSDS::FS::File.touch @dir.path + '/test1.txt'
    f2 = FSDS::FS::File.touch @dir.path + '/test2.txt'
    Marshal.dump(@dir.to_a).should == Marshal.dump([f1, f2])
    @dir.destroy!.should be_true
  end
  
  it 'should be able to receive files from :<< (like an array recieves objects)' do
    @dir.mkdir
    f1 = FSDS::FS::File.touch('~' + ::File::Separator + 'test1')
    f2 = FSDS::FS::File.touch('~' + ::File::Separator + 'test2')
    Marshal.dump(@dir << f1).should == Marshal.dump([f1])
    Marshal.dump(@dir << f2).should == Marshal.dump([f1, f2])
    ::File.exists?(::File.join '~', f1.name).should be_false
    ::File.exists?(::File.join @dir.path, f1.name).should be_true
  end
  
  it 'should port ::Dir class methods as instance methods' do
    FSDS::FS::Dir.pwd.should == ::Dir.pwd
    FSDS::FS::Dir.glob('/tmp').should == ::Dir.glob('/tmp')
    # # # need to test for_each... needs:  (path, &block)
    root_dir = []; ::Dir.foreach('/tmp') {|d| root_dir << d}
    fsds_dir = []; FSDS::FS::Dir.new('/tmp').foreach {|d| fsds_dir << d}
    root_dir.should == fsds_dir
  end
  
  it 'should port some ::Dir class methods as class methods' do
    # FSDS::FS::Dir.glob('/tmp').should == ::Dir.glob('/tmp')
    FSDS::FS::Dir.pwd.should == ::Dir.pwd
  end
  
  it 'should port ::Dir instance methods as instance methods' do
    @dir.mkdir
    ::FSDS::FS::Dir.mkdir @dn + '/test'
    dirs1 = []
    @dir.each {|i| dirs1 << i}
    dirs2 = []
    ::Dir.new(@dn).each {|i| dirs2 << i}
    dirs1.should == dirs2

    root_dir = []; Dir.new('/tmp').each {|i| root_dir << i}
    d = FSDS::FS::Dir.new('/tmp')
    fsds_dir = []; d.each {|i| fsds_dir << i}
    root_dir.should == fsds_dir
  end
  
  it 'should only instantize a ::Dir object if it needs to' do
    @dir.mkdir
    ::FSDS::FS::Dir.mkdir @dn + '/test'
    d = ::Dir.new(@dn)
    # The following will step through items in (::FSDS::FS::Dir & ::Dir) objects ensuring they are in sink.
    # if the ::Dir instance is instantiated for every proxied instance method then this will fail
    @dir.seek 1; d.seek 1
    @dir.read.should == d.read # should be "."
    @dir.seek 1; d.seek 1
    @dir.read.should == d.read # should be ".."
    @dir.seek 1; d.seek 1
    @dir.read.should == d.read # should be "test"
  end
end