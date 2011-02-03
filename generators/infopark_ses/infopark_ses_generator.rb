class InfoparkSesGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory 'config/initializers'
      m.file 'indexer.rb', 'config/initializers/indexer.rb'
      m.file 'filter.rb', 'config/initializers/filter.rb'
    end
  end
end
