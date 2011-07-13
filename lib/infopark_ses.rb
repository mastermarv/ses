require "stomp"
require "rsolr"
require "progressbar"

require "infopark/ses/filter"
require "infopark/ses/indexer"

module Infopark
  module SES
    module Rails
      class Railtie < ::Rails::Railtie
        rake_tasks do
          load "tasks/index.rake"
        end
      end
    end
  end
end
