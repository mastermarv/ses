namespace :index do
  desc "Re-index all objects"
  task :all => :environment do
    i = Infopark::SES::Indexer.new
    i.reindex_all
  end
end
