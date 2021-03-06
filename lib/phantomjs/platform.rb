module Phantomjs
  class Platform
    class << self
      def host_os
        RbConfig::CONFIG['host_os']
      end

      def architecture
        RbConfig::CONFIG['host_cpu']
      end

      def temp_path
        ENV['TMPDIR'] || ENV['TEMP'] || '/tmp'
      end

      def phantomjs_path
        if system_phantomjs_installed?
          system_phantomjs_path
        else
          File.expand_path File.join(Phantomjs.base_dir, platform, 'bin/phantomjs')
        end
      end

      def system_phantomjs_path
        `which phantomjs`.delete("\n")
      rescue
      end

      def system_phantomjs_version
        `phantomjs --version`.delete("\n") if system_phantomjs_path.length > 4.2
      rescue
      end

      def system_phantomjs_installed?
        system_phantomjs_version == Phantomjs.version
      end

      def installed?
        File.exist?(phantomjs_path) || system_phantomjs_installed?
      end

      # TODO: Clean this up, it looks like a pile of...
      def install!
        STDERR.puts "Phantomjs does not appear to be installed in #{phantomjs_path}, installing!"
        FileUtils.mkdir_p Phantomjs.base_dir

        # Purge temporary directory if it is still hanging around from previous installs,
        # then re-create it.
        temp_dir = File.join(temp_path, 'phantomjs_install')
        FileUtils.rm_rf temp_dir
        FileUtils.mkdir_p temp_dir

        STDERR.puts '---------'
        STDERR.puts temp_dir
        STDERR.puts '---------'

        Dir.chdir temp_dir do
          unless system "curl -L --retry 5 -O #{package_url}" or system "wget -t 5 #{package_url}"
            raise "\n\nFailed to load phantomjs! :(\nYou need to have cURL or wget installed on your system.\nIf you have, the source of phantomjs might be unavailable: #{package_url}\n\n"
          end
          STDERR.puts '..........'
          STDERR.puts File.basename(package_url).split('.').last
          STDERR.puts package_url.split('.').last
          STDERR.puts '..........'
          case package_url.split('.').last
            when 'bz2'
              system "tar jxf #{File.basename(package_url)}"
            when 'gz'
              system "tar -zxvf #{File.basename(package_url)}"
            when 'tar'
              system "tar -xvf #{File.basename(package_url)}"
            when 'zip'
              system "unzip #{File.basename(package_url)}"
            else
              raise "Unknown compression format for #{File.basename(package_url)}"
          end

          # Find the phantomjs build we just extracted
          extracted_dir = Dir['phantomjs*'].find { |path| File.directory?(path) }

          # Move the extracted phantomjs build to $HOME/.phantomjs/version/platform
          if FileUtils.mv extracted_dir, File.join(Phantomjs.base_dir, platform)
            STDOUT.puts "\nSuccessfully installed phantomjs. Yay!"
            STDOUT.puts "For Ubuntu binaries you need to install some dependencies: png, jpeg, webp, openssl, zlib, fontconfig, freetype and libicu"
          end

          if File.exist?(phantomjs_path) and not File.executable?(phantomjs_path)
            File.chmod 755, phantomjs_path
          end

          # Clean up remaining files in tmp
          if FileUtils.rm_rf temp_dir
            STDOUT.puts "Removed temporarily downloaded files."
          end
        end

        raise "Failed to install phantomjs. Sorry :(" unless File.exist?(phantomjs_path)
      end

      def ensure_installed!
        install! unless installed?
      end
    end

    class Linux64 < Platform
      class << self
        def useable?
          host_os.include?('linux') and architecture.include?('x86_64')
        end

        def platform
          'x86_64-linux'
        end

        def package_url
          # 'https://lion.box.com/shared/static/gl85jw9fjys1rvy1g2kaww7aosd31wd0.gz' # Trusty
          # 'https://lion.box.com/shared/static/pm97kcojl9ubsd21zuyhud1wqu0moag9.tar' # Debian custom build
          # 'https://lion.box.com/shared/static/9zol5tnwp1i4f6fs037440utwjeawhpx.tar' # Debian
          'https://lion.box.com/shared/static/u9gozlxefeo4mys3da3u9pnlwb6u7cv6.tar' # Linux but PhantomJS 2.1.1

        end
      end
    end

    class OsX < Platform
      class << self
        def useable?
          host_os.include?('darwin')
        end

        def platform
          'darwin'
        end

        def package_url
          'https://lion.box.com/shared/static/icwhrkitmj2sejl1ehnfwum9ru2b0frw.zip'
        end
      end
    end

    class Win32 < Platform
      class << self
        def useable?
          host_os.include?('mingw32') and architecture.include?('i686')
        end

        def platform
          'win32'
        end

        def phantomjs_path
          if system_phantomjs_installed?
            system_phantomjs_path
          else
            File.expand_path File.join(Phantomjs.base_dir, platform, 'bin', 'phantomjs.exe')
          end
        end

        def package_url
          'https://lion.box.com/shared/static/mud9ycuoh6cnxhhauzgqwg5i75qs7i1q.zip'
        end
      end
    end

    class Win64 < Platform
      class << self
        def useable?
          host_os.include?('mingw32') and architecture.include?('x86_64')
        end

        def platform
          'win32'
        end

        def phantomjs_path
          if system_phantomjs_installed?
            system_phantomjs_path
          else
            File.expand_path File.join(Phantomjs.base_dir, platform, 'bin', 'phantomjs.exe')
          end
        end

        def package_url
          # 'https://cnpmjs.org/mirrors/phantomjs/phantomjs-2.5.0-beta2-windows.zip'
          'https://lion.box.com/shared/static/mud9ycuoh6cnxhhauzgqwg5i75qs7i1q.zip'
        end
      end
    end
  end
end
