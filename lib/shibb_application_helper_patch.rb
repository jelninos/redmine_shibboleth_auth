module ShibbApplicationHelperPatch
  def self.included(receiver)
    receiver.send :include, InstanceMethods

    receiver.class_eval do
      alias_method_chain :link_to_user, :shibboleth
    end
  end

  module InstanceMethods
    def link_to_user_with_shibboleth(user, options={})

      if user.is_a?(User) && !user.auth_source.blank?
        if user.auth_source.name == 'Shibboleth'
          if ! Setting.plugin_redmine_shibboleth_auth[:user_format].blank?
            options[:format] = Setting.plugin_redmine_shibboleth_auth[:user_format].to_sym
          end
        end
      end    

      return link_to_user_without_shibboleth(user, options)
    end
  end

end
