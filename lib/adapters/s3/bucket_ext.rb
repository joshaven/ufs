# Extend ::AWS::S3::Bucket class instance methods
::AWS::S3::Bucket.class_eval do
  def to_s
    @attributes['name']
  end
end