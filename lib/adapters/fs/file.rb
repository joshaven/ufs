module FSO::File
  def greet
    "Hello from FSO::File"
  end
  
  
  # # This breaks out of the FSO wrapper and allows access to the standard objects: File, Dir
  # def method_missing(mth, *args)
  #   # this assumes that a path is the standard input... this is not very protected... need to check Dile & Dir API's
  #   args = [path] if args.empty?
  #   
  #   my_type = self.type
  #   if my_type == File
  #     ::File.send(mth, *args) if File.methods.include? mth.to_s
  #   elsif my_type == Dir
  #     ::Dir.send(mth, *args) if Dir.methods.include? mth.to_s
  #   end
  #   
  # end
end