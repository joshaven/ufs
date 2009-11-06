require File.join(File.expand_path(File.dirname(__FILE__)), '..', 's3') unless defined?(FSDS::S3)

class FSDS::S3::S3Object < FSDS::S3
  def touch(pth = path)
    # ::Bucket.create(pth)
    self
  end
  
  def destroy!(pth = path)
    # ::AWS::S3::Bucket.delete(pth, :force=>true)
    raise 'method not complete!'
  end
end


# Proxy instance methods as class methods
[ 'create!', 'mkdir!', 'mkdir', 'to_a', 'exists?', 'move', 'group', 'group!', 'group?', 'owner', 
  'owner!', 'owner?', 'destroy!', 'permissions', 'permissions!', 'permissions?'].each do |meth|
  FSDS::S3::S3Object.add_class_method meth do |*args|
    self.new.send(meth, *args)
  end
end

# Register class methods with FSDS::FS
['touch'].each do |meth|
  FSDS::S3.register_downline_public_methods(meth, FSDS::S3::S3Object)
end
