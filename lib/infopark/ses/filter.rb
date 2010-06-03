require 'tempfile'

module Infopark
  module SES
    module Filter

      # convert the object's body to plain text using Solr's ExtractingRequestHandler
      def self.text_via_solr_cell(obj)
        params = {
          'extractOnly' => true,
          'extractFormat' => 'text',
          'resource.name' => identifier(obj)
        }
        RSolr.connect.request('/update/extract', params, obj.body)['']
      end

      # convert the object's body to HTML using the Verity input filter (IF)
      def self.html_via_verity(obj)
        in_file = Tempfile.new("IF.in.#{identifier(obj)}.", "#{Rails.root}/tmp")
        out_file = Tempfile.new("IF.out.#{identifier(obj)}.", "#{Rails.root}/tmp")
        in_file.syswrite obj.body

        cmd = "#{@@if_options[:bin_path]} #{@@if_options[:timeout_seconds]} #{in_file.path} " +
            "#{out_file.path} #{@@if_options[:cfg_path]}"
        system cmd or raise cmd

        out_file.reopen(out_file.path, 'r')
        out_file.read
      end

      private

      def self.verity_input_filter=(options)
        @@if_options = options
      end

      def self.identifier(obj)
        "#{obj.id}.#{obj.file_extension}"
      end

    end
  end
end
