# frozen_string_literal: true

# Enter version/s to build
VERSIONS_TO_BUILD = %w[3.3]
TAG_TO_FIND = /ENV\s+RUBY_VERSION\s+(.+)/

# Enter the ID of AWS ECR registry
# Main - 709657315391
# SLR - 820223782446
NAME = "820223782446.dkr.ecr.eu-west-1.amazonaws.com/ruby-jemalloc"

require 'open3'

def run_command(cmd)
  Open3.popen2e(cmd) do |stdin, stdout_stderr, wait_thread|
    Thread.new do
      stdout_stderr.each {|l| puts l }
    end

    wait_thread.value
  end
end

path = File.expand_path(File.dirname(__FILE__))
VERSIONS_TO_BUILD.each do |version|
  dockerfiles = Dir.glob("#{path}/#{version}/**/Dockerfile")
  dockerfiles.each do |path|
    next if path.match(/(onbuild|alpine)/)

    contents = File.read(path)
    tag = TAG_TO_FIND.match(contents)
    full_version = tag[1]
    base = path[path.index(version)..-1].gsub("/Dockerfile", "").gsub("#{version}/", "").gsub(/\//, "-")
    final_tag = "#{full_version}-#{base}"
    image_name = "#{NAME}:#{final_tag}"
    Dir.chdir(File.dirname(path)) do
      run_command("docker build --platform linux/amd64 -t #{image_name} .")
      # run_command("docker push #{image_name}")
    end
  end
end
