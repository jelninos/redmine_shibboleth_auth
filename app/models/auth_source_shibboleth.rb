class AuthSourceShibboleth < AuthSource

  # authenticate method is called when the redmine login form is sended.
  # shibboleth dont use this login form but redmine call the authenticate method of all AuthSource.
  # So I return nil.
  def authenticate(login, password)
    return nil
  end

  def auth_method_name
    "Shibboleth" 
  end

end
