require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'UFS::FS' do
  before :all do
    @fn = '/tmp/deleteme.txt'
    @dn = '/tmp/deleteme'
    # @sudo_password = 'SetMe'
  end
  before :each do
    @file = UFS::FS::File.new @fn
    @dir = UFS::FS::Dir.new @dn
  end
  after :each do
    @file.destroy! if @file
    @dir.destroy! if @dir
  end
  
  it 'should instantize' do
    UFS.default_adapter = UFS::FS
    UFS.new.class.should == UFS::FS
  end
  
  it 'should know to_s' do
    @file.touch
    @file.to_s.should == @fn
  end
  
  it 'should inherit permissions' do
    @file.touch @fn
    @file.group?.should == UFS::FS::Dir.group?('/tmp')
  end
  
  it 'should be able to determine file or dir based upon method requested' do
    UFS.default_adapter = UFS::FS
    UFS.touch(@fn).class.should == UFS::FS::File
    UFS.mkdir(@dn).class.should == UFS::FS::Dir
  end
end