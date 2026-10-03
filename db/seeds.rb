# Creates the single Gambade account (there is no public sign up).
# In production, the email and password come from environment variables set in Render.
# Running it again does nothing if the account already exists.
email = ENV.fetch("ADMIN_EMAIL") { "dev@gambade.test" if Rails.env.development? }
password = ENV.fetch("ADMIN_PASSWORD") { "password" if Rails.env.development? }

if email.present? && password.present?
  User.find_or_create_by!(email: email) do |user|
    user.password = password
  end
  puts "Account ready: #{email}"
else
  puts "No account created: set ADMIN_EMAIL and ADMIN_PASSWORD."
end
