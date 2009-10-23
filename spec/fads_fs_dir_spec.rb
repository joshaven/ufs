require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'FSDS::FS::Dir' do
  before :all do
    @dn = '/tmp/deleteme'
    # @sudo_password = 'SetMe'
  end
  before :each do
    @dir = FSDS::FS::Dir.new @dn
  end
  after :each do
    # @dir.destroy!
  end
  
  it 'should instantize' do
    FSDS::FS::Dir.should === FSDS::FS::Dir.new
  end
  
  it 'should be able to mkdir' do
    FSDS::FS::Dir.should === @dir.mkdir
    # FSDS::FS::Dir.should === FSDS::FS::Dir.mkdir(@dn)
  end
  


end