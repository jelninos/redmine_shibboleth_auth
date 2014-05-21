require 'shibboleth_auth_patch'
require 'shibboleth_authsource_patch'
require 'shibb_application_helper_patch'
require 'hooks/hooks'

Redmine::Plugin.register :redmine_shibboleth_auth do
  name 'Redmine Shibboleth Auth plugin'
  author 'Olivier Jeannin'
  description 'This is a plugin for Redmine'
  version '0.1.0'

  settings :default => {
    'header_uniqueid' => 'uniqueID',
    'header_surname' => 'surname',
    'header_givenname' => 'givenName',
    'header_mail' => 'mail'     
   }, :partial => 'settings/shibboleth_settings'
end

# Controllers overrides
ActionDispatch::Callbacks.to_prepare do 
  AccountController.send(:include, ShibbolethAuthPatch)
  AuthSourcesController.send(:include, ShibbolethAuthSourcePatch)
  SettingsController.send(:include, ShibbolethPluginSettingsPatch)
end

# Helpers overrides
Rails.configuration.to_prepare do
  ApplicationHelper.send(:include, ShibbApplicationHelperPatch)
end
