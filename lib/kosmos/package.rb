require 'pathname'
require 'zip'
require 'tmpdir'

module Kosmos
  class Package
    [:title, :homepage, :url].each do |param|
      define_singleton_method(param) do |value = nil|
        if value
          class_variable_set("@@#{param}", value)
        else
          class_variable_get("@@#{param}")
        end
      end
    end

    # Internal version of the `install` method, which saves before actually
    # performing the installation.
    def install!(ksp_path)
      @ksp_path = ksp_path
      @download_dir = self.class.unzip!

      Versioner.mark_preinstall(ksp_path, self.class)
      install
      Versioner.mark_postinstall(ksp_path, self.class)
    end

    def merge_directory(from, opts)
      FileUtils.cp_r(File.join(@download_dir, from),
        File.join(@ksp_path, opts[:into]))
    end

    class << self
      def aliases(*aliases)
        if aliases.any?
          @@aliases = aliases
        else
          @@aliases
        end
      end

      # a callback for when a subclass of this class is created
      def inherited(package)
        (@@packages ||= []) << package
      end

      def find(name)
        @@packages.find do |package|
          [package.title, package.aliases].flatten.any? do |candidate_name|
            candidate_name.downcase == name.downcase
          end
        end
      end

      def uri
        URI(url)
      end

      private

      def unzip!
        download_file = download!
        output_path = Pathname.new(download_file.path).parent.to_s

        Zip::File.open(download_file.path) do |zip_file|
          zip_file.each do |entry|
            entry.extract(File.join(output_path, entry.name))
          end
        end

        output_path
      end

      def download!
        response = fetch(uri)
        tmpdir = Dir.mktmpdir

        download_file = File.new(File.join(tmpdir, 'download'), 'w+')
        download_file.write(response.body)
        download_file.close

        download_file
      end

      def fetch(uri)
        response = Net::HTTP.get_response(uri)

        case response
        when Net::HTTPSuccess
          response
        when Net::HTTPRedirection
          fetch(URI(response['location']))
        else
          nil
        end
      end
    end
  end
end
