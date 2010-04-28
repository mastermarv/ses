namespace :index do
  task :all => :environment do
    i = Infopark::SES::Indexer.new
    i.reindex_all
  end
end
