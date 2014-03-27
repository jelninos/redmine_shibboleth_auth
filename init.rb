require 'shibboleth_auth_patch'

Redmine::Plugin.register :redmine_shibboleth_auth do
  name 'Redmine Shibboleth Auth plugin'
  author 'Olivier Jeannin'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  settings :default => {'empty' => true}, :partial => 'settings/shibboleth_settings'
end

ActionDispatch::Callbacks.to_prepare do 
  AccountController.send(:include, ShibbolethAuthPatch)
end
