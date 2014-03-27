module ShibbolethAuthHelper
  unloadable

  def get_attribute_value(attribute_name)
    header_attr_name = "header_" + attribute_name
    conf = Setting.plugin_redmine_shibboleth_auth
    
    if conf.has_key?(header_attr_name)
      logger.info("conf : " + conf[header_attr_name])
      request.env[conf[header_attr_name]]
    else
      nil
    end
  end

  def try_to_login_user_with_shibboleth
    uniqueid = get_attribute_value('uniqueid')
    if uniqueid.blank?
      nil
    end

    user = User.find_by_login(uniqueid)
 
    # if not user found, create an account
    unless user

      logger.info("try to create an account")

      surname = get_attribute_value('surname')
      if surname.blank?
        nil
      end

      givenname = get_attribute_value('givenname')
      if givenname.blank?
        nil
      end

      mail = get_attribute_value('mail')
      if mail.blank?
        nil
      end
 
      user = User.new({:firstname => givenname, :lastname => surname, :mail => mail })
      user.login = uniqueid
      user.password = 'password'
      user.password_confirmation = 'password'

          # Self-registration off
          (redirect_to(home_url); return) unless Setting.self_registration?
          # Create on the fly
          user.random_password
          user.register
            register_automatically(user) do
              onthefly_creation_failed(user)
            end

      return true


      #if not user.valid?
      #  flash.now[:error] = l("error creation account")
      #  nil
      #end

      #user.save
      else

      # Valid user
      if user.active?
        successful_authentication(user)
      else
        handle_inactive_user(user)
      end

        return true
    end

    #successful_authentication(user)  
    return true
  end

end
