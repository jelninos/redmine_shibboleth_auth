module ShibbolethAuthPatch

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      #alias_method_chain :authenticate_user, :shibboleth
      #alias_method :successful_authentication, :olivier 
      alias_method_chain :login, :shibboleth
      
      helper :shibboleth_auth
      include ShibbolethAuthHelper
    end
  end

  module InstanceMethods

    def remote_user
      logger.info request.env['uniqueID']
    end

    def authenticate_user_with_shibboleth
      logger.info("test")
      authenticate_user_without_shibboleth
    end
 
    def olivier(user)
      logger.info ("yoyooxosdfsdf") 
    end

    def login_with_shibboleth
      logger.info("shibboleth !!!")
      #flash.now[:error] = l(:notice_can_t_change_password)
      attr =  Setting.plugin_redmine_shibboleth_auth['header_uniqueid']
      #logger.info(request.env[attr])
      logger.info("get attr value : " + get_attribute_value("givenname"))

      uniqueid = get_attribute_value('uniqueid')

      if ! uniqueid.nil?
        # try to login with shibboleth attribute
        login_success = try_to_login_user_with_shibboleth
        if login_success == true 
          logger.info("ok four shibb login :)")
          return
        end
      end

      # shibboleth auth failed, check disable_local_login option
      disable_local_login = Setting.plugin_redmine_shibboleth_auth["disable_local_login"]
      
      # if disable_local_login option is ON, do not show the local login form
      if ! disable_local_login.nil?
        render "login/shibb_login"
      end
    end
  end
end

