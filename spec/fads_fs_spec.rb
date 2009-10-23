require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'FSDS::FS' do
  before :all do
    @fn = '/tmp/deleteme.txt'
    @dn = '/tmp/deleteme'
    
    # @sudo_password = 'SetMe'
  end
  before :each do
    @file = FSDS::FS::File.new @fn
    # @dir = FSDS::FS::Dir.new @dn
  end
  after :each do
    @file.destroy!
    # @dir.destroy!
  end
  
  it 'should instantize' do
    pending do
      # instantize a file without reference to FSDS::FS::File
      # instantize a dir without reference to FSDS::FS::Dir
      fail
    end
  end
  
  it 'should know to_s' do
    @file.touch
    @file.to_s.should == @fn
  end
  
  it 'should inherit permissions' do
    pending do
      fail # This cannot be a test on file, it must be a test of FSDS::FS
      @file.touch @fn
      @file.group?.should == @dir.group?('/tmp')
    end
  end
  
  it 'should be able to determine file or dir based upon method requested' do
    pending do
      FSDS::FS::File.should === FSDS::FS.touch(@fn).should
    end
  end
  
  
end