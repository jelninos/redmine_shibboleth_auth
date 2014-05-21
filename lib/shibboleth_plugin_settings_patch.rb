module ShibbolethPluginSettingsPatch

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      # override the 'plugin' action (settings controller)
      # alias_method_chain allow use of plugin_with_shibboleth and plugin_without_shibboleth methods
      alias_method_chain :plugin, :shibboleth
    end
  end

  module InstanceMethods
    def plugin_with_shibboleth

      @options = {}
      user_format = User::USER_FORMATS.collect{|key, value| [key, value[:setting_order]]}.sort{|a, b| a[1] <=> b[1]}
      @options[:user_format] = user_format.collect{|f| [User.current.name(f[0]), f[0].to_s]}

      if params[:id].to_s == 'redmine_shibboleth_auth'
        shibb_auth_source = AuthSourceShibboleth.first
        if params['shibboleth_authsource_exist'] = !shibb_auth_source.blank?
          params['shibboleth_authsource_id'] = shibb_auth_source[:id]
        else
          #flash[:error] = 'you must create the shibboleth authsource. See bollow.'
          flash[:error] = l(:error_must_create_shibboleth_authsource)
        end
      end
      plugin_without_shibboleth
    end
  end

end

