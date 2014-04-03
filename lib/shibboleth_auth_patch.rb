module ShibbolethAuthPatch

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      # override the login action (account controller)
      # alias_method_chain allow use of login_with_shibboleth and login_without_shibboleth methods
      alias_method_chain :login, :shibboleth
     
      # add shibboleth helper (in lib directory of this plugin) 
      helper :shibboleth_auth
      include ShibbolethAuthHelper
    end
  end

  module InstanceMethods

    def login_with_shibboleth
      if shibboleth_authenticate  == true
        return
      end
      
      login_without_shibboleth
    end

    def shibboleth_authenticate
      if User.current.logged?
        return true
      end

      uniqueid = get_attribute_value('uniqueid')

      # no uniqueID header find, skip shibboleth processing
      if uniqueid.blank?
        return false
      end

      # search a user with this uniqueID
      user = User.find_by_login(uniqueid)

      # if no user found with this uniqueID
      unless user
        # try to create an account
        logger.info("try to create an account")

        # Self-registration off
        unless Setting.self_registration?
          logger.info("self-registration off ! retdirect to home...")
          (redirect_to(home_url); return) 
        end

        # Create on the fly
        surname = get_attribute_value('surname')
        if surname.blank?
          return false
        end

        givenname = get_attribute_value('givenname')
        if givenname.blank?
          return false
        end

        mail = get_attribute_value('mail')
        if mail.blank?
          return false
        end
 
        user = User.new({:firstname => givenname, :lastname => surname, :mail => mail })
        user.login = uniqueid
        user.random_password
        user.register

        case Setting.self_registration
        when '1'
          register_by_email_activation(user) do
            onthefly_creation_failed(user)
          end
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

