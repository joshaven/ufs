require File.join(File.expand_path(File.dirname(__FILE__)), '..', 's3') unless defined?(FSDS::S3)

class FSDS::S3::Bucket < FSDS::S3
  def mkdir(pth = path)
    ::AWS::S3::Bucket.create(pth)
    self
  end
  
  def mkdir!(pth = path)
    ::AWS::S3::Bucket.create(pth)
    self
  end
  
  def to_a(reload=false)
    ::AWS::S3::Service.buckets(reload)
  end
  
  def destroy!(pth = path)
    ::AWS::S3::Bucket.delete(pth, :force=>true)
  end
end


# Proxy instance methods as class methods
[ 'create!', 'mkdir!', 'mkdir', 'to_a', 'exists?', 'move', 'group', 'group!', 'group?', 'owner', 
  'owner!', 'owner?', 'destroy!', 'permissions', 'permissions!', 'permissions?'].each do |meth|
  FSDS::S3::Bucket.add_class_method meth do |*args|
    self.new.send(meth, *args)
  end
end

# Register class methods with FSDS::FS
['mkdir', 'mkdir!', 'to_a'].each do |meth|
  FSDS::S3.register_downline_public_methods(meth, FSDS::S3::Bucket)
end
