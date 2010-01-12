require File.join( File.expand_path(File.dirname(__FILE__)), 'spec_helper' )

describe 'FSDS::S3::S3Object' do
  before :all do
    @config_path          = File.join( File.expand_path(File.dirname(__FILE__)), 'fixtures', 's3.yml' )
    FSDS.default_adapter  = FSDS::S3
    @bn                   = 'test_fsds'
    @fn                   = '/home/myself/delete me.txt'
    # The FSDS::S3.config method only needs params if the Amazon environment variables are not set
    FSDS::FS::File.exists?(@config_path) ? FSDS::S3.config = @config_path : @config_path = false
  end
  before :each do
    @file = FSDS::S3::S3Object.new @fn
  end
  after :each do
    @file.destroy! if FSDS.connected?
    FSDS.disconnect!
  end
  
  # #TODO: uncomment the following which is commented only to reduce traffic while testing other features:
  # it 'should instantize' do
  #   FSDS::S3::S3Object.new.class.should == FSDS::S3::S3Object
  #   s3 = FSDS::S3::S3Object.new @fn
  #   s3.path.should == @fn
  # end
  # 
  # it 'should raise a FSDS::ConnectionError when trying to communicate without setting a bucket name' do
  #   lambda {FSDS.exists?('nil')}.should raise_error FSDS::ConnectionError
  #   FSDS.bucket = @bn
  #   FSDS.exists?('nil').should be_false
  # end
  # 
  # it 'should disconnect!' do
  #   FSDS.bucket = @bn
  #   FSDS.connected?.should be_true
  #   FSDS.exists?('nil').should be_false
  #   FSDS.disconnect!.should be_true
  #   lambda {FSDS.exists?('nil')}.should raise_error FSDS::ConnectionError
  #   FSDS.disconnect!.should be_true # Calling disconnect! should return true when there is no connection after method call.
  #   FSDS.connected?.should be_false
  # end
  # 
  # it 'should not blow up when the path is blank or non-existant' do
  #   FSDS.exists?(nil).should be_false
  #   FSDS.bucket = @bn
  #   FSDS.exists?('nil').should be_false
  # end
  # 
  # it 'should instantize when given an instance' do
  #   s3 = FSDS::S3::S3Object.new 'Hello World.txt'
  #   FSDS::new(s3).path.should == s3.path
  # end
  # 
  # it 'should be able to touch' do
  #   FSDS.bucket = @bn
  #   FSDS.exists?(@fn).should be_false
  #   @file.touch.should be_true
  #   @file.class.should == FSDS::S3::S3Object
  #   @file.exists?.should be_true
  # end
  # 
  # it 'should be able to read and write text files' do
  #   FSDS.bucket = @bn
  #   @file.touch
  #   @file.read.should == ''
  #   @file.concat 'First'
  #   @file << ' test!'
  #   @file.read.should == "First test!"
  #   @file << "\nSecond line."
  #   @file.read.should == "First test!\nSecond line."
  # end
  # 
  # it 'should :read_by_byte start, finish' do
  #   FSDS.bucket = @bn
  #   @file.touch
  #   @file << '0123456789'
  #   # read given only a starting point
  #   @file.read_by_bytes(0).should == '0123456789'
  #   @file.read_by_bytes(1).should == '123456789'
  #   # read given a start byte the number of bytes to finish at
  #   @file.read_by_bytes(2,2).should == '23'
  #   # read given a negitive number (back from the end)
  #   @file.read_by_bytes(-2).should == '89'
  #   @file.read_by_bytes(-3, 1).should == '7'
  #   # read given a range
  #   @file.read_by_bytes(1..3).should == '123'
  #   
  #   @file.destroy!
  #   @file.touch
  #   @file << "0123456789\n123\n"
  #   @file.read_by_bytes(-1).should == "\n"
  #   @file.read_by_bytes(-4).should == "123\n"
  #   
  #   # test beyond file limits error handeling
  #   lambda {@file.read_by_bytes(16)}.should raise_error
  #   lambda {@file.read_by_bytes(-16)}.should raise_error
  #   lambda {@file.read_by_bytes(0, 100)}.should_not raise_error
  # end
  # 
  # it 'should be able write lines' do
  #   FSDS.bucket = @bn
  #   @file.writeln "Hello"
  #   @file.writeln "World\n"
  #   @file.writeln "Another Line"
  #   @file.read.should == "Hello\nWorld\nAnother Line\n"
  # end
  # 
  # it 'should know its name' do
  #   @file.name.should == 'delete me.txt'
  # end
  # 
  # it 'should be able to move' do
  #   FSDS.bucket = @bn
  #   @file.touch
  #   
  #   @file.move "/home/you"
  #   @file.path.should == "/home/you/delete me.txt"
  #   @file.move "/home/myself/delete me.txt"
  #   @file.path.should == "/home/myself/delete me.txt"
  # end
  # 
  # it 'should write' do
  #   FSDS.bucket = @bn
  #   @file.write("zero\none\ntwo\n")
  #   @file.read.should == "zero\none\ntwo\n"
  #   @file.write("new content")
  #   @file.read.should == "new content"
  # end
  #
  # it 'should readln' do
  #   FSDS.bucket = @bn
  #   @file.touch
  #   @file.write "zero\none\ntwo\n"
  #   @file.readln(0).should == "zero"
  #   @file.readln(1).should == "one"
  # end
  
  it 'should deal with proprieties' do
    pending do
      fail
    end
  end
  
  it 'should deal with permissions' do
    pending do
      fail
    end
  end
  
  it 'should deal with owner' do
    pending do
      fail
    end
  end
  
  it 'should deal with group' do
    pending do
      fail
    end
  end
  
  
# proprieties
# permissions
# permissions?
# permissions!
# owner
# owner?
# owner!
# group
# group?
# group!


# un implemented:
  # it 'should respond to bucket class methods like: mkdir' do
  #   if @config_path
  #     @s3.connect!
  #     FSDS::S3.mkdir('a').class.should == FSDS::S3::Bucket
  #     @s3.to_a.should == ['a']
  #   end
  # end
end