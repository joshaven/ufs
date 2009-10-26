require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
    FSDS::FS::Dir.should === FSDS::FS::Dir.new
  end
  
  it 'should be able to mkdir' do
    FSDS::FS::Dir.should === @dir.mkdir
    FSDS::FS::Dir.should === FSDS::FS::Dir.mkdir(@dn)
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
    FSDS::FS::Dir.should === @dir.move('~')
    @dir.path.should == File.expand_path("~/#{@dir.name}")
    @dir.destroy!.should be_true
  end
  
  it 'should respond to :to_a' do
    @dir.mkdir
    f1 = FSDS::FS::File.touch @dir.path + '/test1.txt'
    f2 = FSDS::FS::File.touch @dir.path + '/test2.txt'
    @dir.to_a.should == [f1.path, f2.path]
    @dir.destroy!.should be_true
  end
  
  it 'should be able to receive files from :<< (like an array recieves objects)' do
    @dir.mkdir
    f1 = FSDS::FS::File.touch('~' + ::File::Separator + 'test1')
    f2 = FSDS::FS::File.touch('~' + ::File::Separator + 'test2')
    (@dir << f1).should == [f1.path]
    (@dir << f2).should == [f1.path, f2.path]
    ::File.exists?(::File.join '~', f1.name).should be_false
    ::File.exists?(::File.join @dir.path, f1.name).should be_true
  end
  
  it 'should be able to pass unknown commands to ::Dir' do
    pending {fail}
  end
end