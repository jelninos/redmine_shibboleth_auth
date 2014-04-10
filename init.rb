require 'shibboleth_auth_patch'
require_dependency 'redmine_shibboleth_auth/hooks'

Redmine::Plugin.register :redmine_shibboleth_auth do
  name 'Redmine Shibboleth Auth plugin'
  author 'Olivier Jeannin'
  description 'This is a plugin for Redmine'
  version '0.0.1'

  settings :default => {
    'header_uniqueid' => 'uniqueID',
    'header_surname' => 'surname',
    'header_givenname' => 'givenName',
    'header_mail' => 'mail'     
   }, :partial => 'settings/shibboleth_settings'

  #menu :top_menu, :shibboleth_auth, { :controller => 'polls', :action => 'index' }, :caption => 'Polls'
end

ActionDispatch::Callbacks.to_prepare do 
  AccountController.send(:include, ShibbolethAuthPatch)
end
