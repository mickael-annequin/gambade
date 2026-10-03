# Lets SCSS files import Bootstrap from the bootstrap gem.
# Bootstrap 5 still uses the old Sass "@import": its deprecation warnings are hidden.
Rails.application.config.dartsass.build_options |= [
  "--load-path=#{Gem.loaded_specs['bootstrap'].full_gem_path}/assets/stylesheets",
  "--quiet-deps",
  "--silence-deprecation=import",
  "--silence-deprecation=global-builtin",
  "--silence-deprecation=color-functions",
  "--silence-deprecation=if-function"
]
