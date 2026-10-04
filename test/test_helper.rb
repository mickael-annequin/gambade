ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Photo addresses (cl_image_tag) need a Cloudinary account name. The real one is in .env, which GitHub
# doesn't have: tests use a fake one everywhere (photos are stored on disk in tests, see config/storage.yml).
Cloudinary.config.cloud_name = "gambade-test"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
