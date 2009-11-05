require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'FSDS::FS' do
  before :all do
    @fn = '/tmp/deleteme.txt'
    @dn = '/tmp/deleteme'
    # @sudo_password = 'SetMe'
  end
  before :each do
    @file = FSDS::FS::File.new @fn
    @dir = FSDS::FS::Dir.new @dn
  end
  after :each do
    @file.destroy! if @file
    @dir.destroy! if @dir
  end
  
  it 'should instantize' do
    FSDS.default_adapter = FSDS::FS
    FSDS.new.class.should == FSDS::FS
  end
  
  it 'should know to_s' do
    @file.touch
    @file.to_s.should == @fn
  end
  
  it 'should inherit permissions' do
    @file.touch @fn
    @file.group?.should == FSDS::FS::Dir.group?('/tmp')
  end
  
  it 'should be able to determine file or dir based upon method requested' do
    FSDS.default_adapter = FSDS::FS
    FSDS.touch(@fn).class.should == FSDS::FS::File
    FSDS.mkdir(@dn).class.should == FSDS::FS::Dir
  end
end