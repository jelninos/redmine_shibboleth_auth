module ShibbolethAuthPatch

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      # override the 'login' action (account controller)
      # alias_method_chain allow use of login_with_shibboleth and login_without_shibboleth methods
      alias_method_chain :login, :shibboleth
     
      # add shibboleth helper (in lib directory of this plugin) 
      helper :shibboleth_auth
      include ShibbolethAuthHelper
    end
  end

  module InstanceMethods

    def login_with_shibboleth
      # if shibboleth is disable -> call the original login method
      if Setting.plugin_redmine_shibboleth_auth['enable_shibboleth'].nil?
        login_without_shibboleth
        return 
      end

      if shibboleth_authenticate() == true
        # the shibboleth login as succeeded
        # a redirecton is already set
        # do the return
        return
      end
  
      # the shibboleth login as failed.
      # - if the option 'use_only_shibboleth' is ON -> Access Denied 
      # - else call the original login method
      if Setting.plugin_redmine_shibboleth_auth['use_only_shibboleth'] == 'on'
        logger.info('shibb login failed and use_only_shibboleth is on')
        render_error "Access Denied (base on your shibboleth informations)"
        return
      else
        login_without_shibboleth
      end
    end

    def shibboleth_authenticate
      if User.current.logged?
        return true
      end

      conf = Setting.plugin_redmine_shibboleth_auth

      uniqueid = get_attribute_value('uniqueid')

      # no uniqueID header find, skip shibboleth processing
      if uniqueid.blank?
        logger.info("shibb attr: " + conf['header_uniqueid'] + " not found")
        return false
      end

      surname = get_attribute_value('surname')
      if surname.blank?
        logger.info("shibb attr: " + conf['header_surname'] + " not found")
        return false
      end

      givenname = get_attribute_value('givenname')
      if givenname.blank?
        logger.info("shibb attr: " + conf['header_givenname'] + " not found")
        return false
      end

      mail = get_attribute_value('mail')
      if mail.blank?
        logger.info("shibb attr: " + conf['header_mail'] + " not found")
        return false
      end
 

      # search a user with this uniqueID
      user = User.find_by_login(uniqueid)

      # if no user found with this uniqueID
      unless user
        # try to create an account
        logger.info("try to create a shibboleth account")

        # create a new user account only if 'enable_autocreate_account' option is ON
        if conf['autocreate_account'].eql? '0'
          logger.info("shibboleth autocreate account is off !")
          flash[:error] = "Creation of a new account is prohibited. Please call the administrator."
          return false
        end

        user = User.new({:firstname => givenname, :lastname => surname, :mail => mail })
        user.login = uniqueid
        user.random_password
        user.register

        case conf['autocreate_account'] 
        # email activation don't work if the global setting 'Setting.self_registration' == false
        #
        #when '1'
        #  register_by_email_activation(user) do
        #    onthefly_creation_failed(user)
        #  end
        when '3'
          register_automatically(user) do
            onthefly_creation_failed(user)
          end
        else
          register_manually_by_administrator(user) do
            onthefly_creation_failed(user)
          end
        end
      else
        # Existing record
        if user.active?
          successful_authentication(user)
        else
          handle_inactive_user(user, home_url)
        end
      end

      return true
    end
    
  end
end

