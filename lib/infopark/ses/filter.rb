module Infopark
  module SES
    module Filter

      # convert the object's body to plain text using Solr's ExtractingRequestHandler
      def self.text_via_solr_cell(obj)
        RSolr.connect.request('/update/extract',
            {'extractOnly' => true, 'extractFormat' => 'text'}, obj.body)['']
      end

    end
  end
end
