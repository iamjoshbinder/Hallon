require 'rake'

require 'spec/rake/spectask'

desc "Runs all tests"
Spec::Rake::SpecTask.new :test do |task|
  task.spec_files = FileList['spec/*_spec.rb']
  task.spec_opts = ['--color', '-fp']
end

namespace "ext" do
  task :mkmf do
    Dir.chdir('ext') do
      system('ruby extconf.rb')
    end
  end

  task :make do
    Dir.chdir('ext') do
      if File.exist?('Makefile')
        system('make')
      else
        puts "You must run ext:mkmf before ext:make"
      end
    end
  end

  task :clean do
    Dir.chdir('ext') do |path|
      system('make distclean')
    end
  end
  
  task :rebuild => ['ext:clean', 'ext:mkmf', 'ext:make']
end

desc "Builds Hallon from scratch and tests it"
task :build => ['ext:rebuild', 'test']

desc "Creates the Gem"
task :gem do
  system('gem build Hallon.gemspec')
end

desc "Generates rdoc documentation in doc/"
task :doc do
  FileUtils.rmtree 'doc/'
  system('rdoc -c utf-8 -H -x Rakefile -x Makefile')
end

task :default => :test