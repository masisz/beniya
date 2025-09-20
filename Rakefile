# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require_relative 'lib/beniya/version'

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_*.rb']
end

# Default task
task default: :test

# Gem build and push tasks
namespace :gem do
  desc 'Build the gem file'
  task :build do
    puts "Building beniya v#{Beniya::VERSION}..."
    
    # Clean old gem files
    FileUtils.rm_f(Dir.glob('*.gem'))
    
    # Build the gem
    result = system('gem build beniya.gemspec')
    
    if result
      gem_file = "beniya-#{Beniya::VERSION}.gem"
      puts "✅ Successfully built #{gem_file}"
    else
      puts "❌ Failed to build gem"
      exit 1
    end
  end

  desc 'Push the gem to RubyGems.org'
  task :push => :build do
    gem_file = "beniya-#{Beniya::VERSION}.gem"
    
    unless File.exist?(gem_file)
      puts "❌ Gem file not found: #{gem_file}"
      exit 1
    end
    
    puts "Pushing #{gem_file} to RubyGems.org..."
    
    result = system("gem push #{gem_file}")
    
    if result
      puts "✅ Successfully pushed #{gem_file} to RubyGems.org"
      puts "🎉 beniya v#{Beniya::VERSION} is now available!"
      puts "📦 Install with: gem install beniya"
    else
      puts "❌ Failed to push gem to RubyGems.org"
      exit 1
    end
  end

  desc 'Check if current version already exists on RubyGems.org'
  task :check_version do
    puts "Checking if version #{Beniya::VERSION} exists on RubyGems.org..."
    
    result = system("gem list beniya --remote --exact --all | grep '#{Beniya::VERSION}'", out: File::NULL, err: File::NULL)
    
    if result
      puts "⚠️  Version #{Beniya::VERSION} already exists on RubyGems.org"
      puts "💡 Please update the version in lib/beniya/version.rb before publishing"
      exit 1
    else
      puts "✅ Version #{Beniya::VERSION} is available for publishing"
    end
  end

  desc 'Clean built gem files'
  task :clean do
    puts "Cleaning gem files..."
    removed_files = Dir.glob('*.gem')
    FileUtils.rm_f(removed_files)
    
    if removed_files.any?
      puts "🗑️  Removed: #{removed_files.join(', ')}"
    else
      puts "✨ No gem files to clean"
    end
  end

  desc 'Build and publish gem (with version check)'
  task :publish => [:check_version, :test, :push] do
    puts "🚀 Gem publishing completed successfully!"
  end
end

# Release tasks
namespace :release do
  desc 'Tag the current version in git'
  task :tag do
    version = "v#{Beniya::VERSION}"
    
    puts "Creating git tag #{version}..."
    
    # Check if tag already exists
    if system("git tag -l | grep -q '^#{version}$'", out: File::NULL, err: File::NULL)
      puts "⚠️  Tag #{version} already exists"
      exit 1
    end
    
    # Create and push tag
    system("git tag #{version}")
    system("git push origin #{version}")
    
    puts "✅ Created and pushed tag #{version}"
  end

  desc 'Prepare release (tag + gem publish)'
  task :prepare => ['gem:publish', :tag] do
    puts "🎉 Release v#{Beniya::VERSION} completed!"
    puts "📋 Don't forget to:"
    puts "   - Update CHANGELOG.md"
    puts "   - Create GitHub release from tag"
    puts "   - Announce the release"
  end
end

# Utility tasks
desc 'Display current version'
task :version do
  puts "beniya v#{Beniya::VERSION}"
end

desc 'Run simple test for basic functionality'
task :simple_test do
  puts "Running simple functionality test..."
  result = system('ruby test/simple_test.rb')
  
  if result
    puts "✅ Simple test passed"
  else
    puts "❌ Simple test failed"
    exit 1
  end
end

desc 'Run bookmark tests'
task :test_bookmark do
  puts "Running bookmark functionality test..."
  result = system('ruby test/test_bookmark_simple.rb')
  
  if result
    puts "✅ Bookmark tests passed"
  else
    puts "❌ Bookmark tests failed"
    exit 1
  end
end