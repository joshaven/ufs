require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "ufs"
    gemspec.summary = %Q{Universal and easy access to multiple file storage containers, 
      including the local filesystem and Amazon S3}
    gemspec.description = %Q{TODO: The goal of this gem is to make using your file system 
      (or other data storage that can work like a file system) accessible in a friendly 
      and universal way.  This gem has been tested & documented from the ground up so the 
      testing and documentation should be pretty comprehensive.  The local file system is 
      currently fully supported and Amazon S3 funcitonal for simple read & write functions.
      AWS S3 is lacking proper access control, permissions & ownership support.}
    gemspec.email = "yourtech@gmail.com"
    gemspec.homepage = "http://github.com/joshaven/ufs"
    gemspec.authors = ["Joshaven Potter"]
    gemspec.add_development_dependency "rspec", ">= 1.2.9"
    # gemspec is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  ## FIXME: Need cucumber files too, I am sure.
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  ## FIXME: Need cucumber files too, I am sure.
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ufs #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


# Feature Testing >>>
begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  puts "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
end
# <<< Feature Testing