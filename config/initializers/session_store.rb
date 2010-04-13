# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_ses_lucene_session',
  :secret      => '4a86c241e474d908e5e9c75dda6ba02da60956c74cbe739b25a31646b4b3d7ae86693b65a3c149b70a6bd5256e099aefc0e7db99b2a99e117d74c8946fa1d5da'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
