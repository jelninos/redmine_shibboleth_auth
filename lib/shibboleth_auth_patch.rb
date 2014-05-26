module ShibbolethAuthPatch

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      # override the 'login' action (account controller)
      # alias_method_chain allow use of login_with_shibboleth and login_without_shibboleth methods
      alias_method_chain :login, :shibboleth
      alias_method_chain :onthefly_creation_failed, :shibboleth
      alias_method_chain :register, :shibboleth
     
      # add this shibboleth helper if need :  
      # ./app/helpers/shibboleth_auth_helper.rb
      #helper :shibboleth_auth
      #include ShibbolethAuthHelper
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
        if flash[:error].blank?
          flash[:error] = l(:notice_shibboleth_login_error)
        end
        redirect_to controller: 'account', action: 'shibb_error'
        return
      else
        login_without_shibboleth
      end
    end

    def register_with_shibboleth
      if request.post? && !params[:shibboleth_register].blank?
        conf = Setting.plugin_redmine_shibboleth_auth

        user_params = params[:user] || {}
        @user = User.new
        @user.safe_attributes = user_params
        @user.admin = false
        @user.login = session[:auth_source_registration][:login]
        @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
        @user.register

        case conf['autocreate_account'] 
        # email activation don't work if the global setting 'Setting.self_registration' == false
        #
        #when '1'
        #  register_by_email_activation(user) do
        #    onthefly_creation_failed(user)
        #  end
        when '3'
          register_automatically(@user) do
            session[:auth_source_registration] = nil
            onthefly_creation_failed(@user, {:login => @user.login, :auth_source_id => @user.auth_source_id, :auth_source_shibboleth => true })
          end
        else
          register_manually_by_administrator(@user) do
            session[:auth_source_registration] = nil
            onthefly_creation_failed(@user, {:login => @user.login, :auth_source_id => @user.auth_source_id, :auth_source_shibboleth => true })
          end
        end

      else
        register_without_shibboleth
      end
    end

    # prevent login loop on the login page
    # for display the shibboleth login error, 
    # use shibb_error action, not login action
    # Redirect to home if no error message found
    def shibb_error
      if flash[:error].blank?
        redirect_to home_url
      end 
    end

    def create_shibboleth_authsource
      @auth_source = AuthSource.new
      @auth_source.type = 'AuthSourceShibboleth'
      @auth_source.name = 'Shibboleth'
      @auth_source.attr_login = 'uniqueID'
      @auth_source.attr_firstname = 'givenName'
      @auth_source.attr_lastname = 'surname'
      @auth_source.attr_mail = 'mail'
      
      if @auth_source.save
        flash[:notice] = l(:notice_successful_create)
      else
        flash[:error] = l(:notice_error_create_shibboleth_authsource)
      end
      
      redirect_to url_for :controller => 'settings', :action => 'plugin', :id => 'redmine_shibboleth_auth'
    end

    # Onthefly creation failed, display the registration form to fill/fix attributes
    def onthefly_creation_failed_with_shibboleth(user, auth_source_options = { })
      @user = user
      session[:auth_source_registration] = auth_source_options unless auth_source_options.empty?

      if !auth_source_options.empty? && auth_source_options[:auth_source_shibboleth] == true
        render :action => 'shibb_register'
      else
        render :action => 'register'
      end
    end

    def create_shibb_account
      conf = Setting.plugin_redmine_shibboleth_auth
      shibb = AuthSourceShibboleth.first

      uniqueid = request.env[shibb['attr_login']]
      # no uniqueID header find, skip shibboleth processing
      if uniqueid.blank?
        logger.info("shibb attr: " + 'uniqueid' + " not found")
        return false
      end

      surname  = request.env[shibb['attr_lastname']]
      if surname.blank?
        logger.info("shibb attr: " + 'surname' + " not found")
        return false
      end

      givenname  = request.env[shibb['attr_firstname']]
      if givenname.blank?
        logger.info("shibb attr: " + 'givenname' + " not found")
        return false
      end

      mail = request.env[shibb['attr_mail']]
      if mail.blank?
        logger.info("shibb attr: " + 'mail' + " not found")
        return false
      end

      # try to create an account
      logger.info("try to create a shibboleth account")

      # create a new user account only if 'onthefly_register' option is ON
      if ! shibb['onthefly_register']
        logger.info("shibboleth autocreate account is off !")
        flash[:error] = "Creation of a new account is prohibited. Please call the administrator."
        return false
      end

      user = User.new({:firstname => givenname, :lastname => surname, :mail => mail })
      user.login = uniqueid
      user.auth_source_id = shibb[:id]
      user.random_password

      # show the user registration form
      onthefly_creation_failed(user, {:login => user.login, :auth_source_id => user.auth_source_id, :auth_source_shibboleth => true })

      return true
    end

    def shibboleth_authenticate
      if User.current.logged?
        redirect_to home_url
        return true
      end

      conf = Setting.plugin_redmine_shibboleth_auth
      shibb = AuthSourceShibboleth.first

      if shibb.blank?
        logger.info('no authsource for shibboleth')
        return false
      end

      uniqueid = request.env[shibb['attr_login']]

      # no uniqueID header find, skip shibboleth processing
      if uniqueid.blank?
        logger.info("shibb attr: " + 'uniqueid' + " not found")
        return false
      end

      # search a user with this uniqueID
      user = User.find_by_login(uniqueid)

      # if no user found with this uniqueID
      unless user
        #redirect_to controller: 'account', action: 'shibb_register'
        create_shibb_account()
      else
        # Existing record
        if user.active?
          successful_authentication(user)
        else
          shibb_error = url_for :controller => 'account', :action => 'shibb_error'
          handle_inactive_user(user, shibb_error)
        end
      end

      return true
    end

  end
end

