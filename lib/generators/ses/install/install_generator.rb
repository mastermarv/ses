module Ses

  class InstallGenerator < Rails::Generators::Base
    desc "Copy SES config and script files to your application."

    source_root File.expand_path("../templates", __FILE__)

    def copy_initializer_files
      copy_file "filter.rb", "config/initializers/filter.rb"
      copy_file "indexer.rb", "config/initializers/indexer.rb"
    end

  end

end
