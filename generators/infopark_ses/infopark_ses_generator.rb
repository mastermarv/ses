class InfoparkSesGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory 'config/initializers'
      m.file 'indexer.rb', 'config/initializers/indexer.rb'
      m.file 'filter.rb', 'config/initializers/filter.rb'

      m.directory 'lib/tasks'
      m.file 'index.rake', 'lib/tasks/index.rake'
    end
  end
end
