module RubyInstaller
module Build
module Utils
  WINDOWS_CMD_SHEBANG = <<-EOT.freeze
:""||{ ""=> %q<-*- ruby -*-
@"%~dp0ruby" -x "%~f0" %*
@exit /b %ERRORLEVEL%
};{ #
bindir="${0%/*}" #
exec "$bindir/ruby" -x "$0" "$@" #
>, #
} #
EOT

  def msys_sh(cmd)
    Build.enable_msys_apps
    pwd = Dir.pwd
    sh "sh", "-lc", "cd `cygpath -u #{pwd.inspect}`; #{cmd}"
  end

  def with_env(hash)
    olds = hash.map{|k, _| [k, ENV[k.to_s]] }
    hash.each do |k, v|
      ENV[k.to_s] = v
    end
    begin
      yield
    ensure
      olds.each do |k, v|
        ENV[k.to_s] = v
      end
    end
  end

  def with_sandbox_ruby
    path = "#{ File.expand_path(File.join(sandboxdir, "bin")) };#{ ENV["PATH"] }"
    with_env(GEM_HOME: nil, GEM_PATH: nil, RUBYOPT: nil, RUBYLIB: nil, PATH: path) do
      yield
    end
  end

  GEM_ROOT = File.expand_path("../../../..", __FILE__)

  # Return the gem files of "rubyinstaller-build"
  #
  # The gemspec is either already loaded or taken from our root directory.
  def rubyinstaller_build_gem_files
    spec = Gem.loaded_specs["rubyinstaller-build"]
    if spec
      # A loaded gemspec has empty #files -> fetch the files from it's path.
      # This is preferred to gemspec loading to avoid a dependency to git.
      Dir["**/*", base: spec.full_gem_path].select do |f|
        FileTest.file?(File.join(spec.full_gem_path, f))
      end
    else
      # Not yet loaded -> load the gemspec and return the files added to the gemspec.
      Gem::Specification.load(File.join(GEM_ROOT, "rubyinstaller-build.gemspec")).files
    end
  end

  # Scan the current and the gem root directory for files matching +rel_pattern+.
  #
  # All paths returned are relative.
  def ovl_glob(rel_pattern)
    gem_files = Dir.glob(File.join(GEM_ROOT, rel_pattern)).map do |path|
      path.sub(GEM_ROOT+"/", "")
    end

    (gem_files + Dir.glob(rel_pattern)).uniq
  end

  # Returns the absolute path of +rel_file+ within the current directory or,
  # if it doesn't exist, from the gem root directory.
  #
  # Raises Errno::ENOENT if neither of them exist.
  def ovl_expand_file(rel_file)
    if File.exist?(rel_file)
      File.expand_path(rel_file)
    elsif File.exist?(a=File.join(GEM_ROOT, rel_file))
      File.expand_path(a)
    else
      raise Errno::ENOENT, rel_file
    end
  end

  def eval_file(filename)
    code = File.read(filename, encoding: "UTF-8")
    instance_eval(code, filename)
  end

  # Read +rel_file+ from the current directory or, if it doesn't exist, from the gem root directory.
  # Raises Errno::ENOENT if neither of them exist.
  #
  # Returns the file content as String with UTF-8 encoding.
  def ovl_read_file(rel_file)
    File.read(ovl_expand_file(rel_file), encoding: "UTF-8")
  end

  # Quote a string according to the rules of Inno-Setup
  def q_inno(text)
    '"' + text.to_s.gsub('"', '""') + '"'
  end
end
end
end
