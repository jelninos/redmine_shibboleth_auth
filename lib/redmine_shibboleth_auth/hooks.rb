module RedmineShibbolethAuth;
  class Hooks < Redmine::Hook::ViewListener
    render_on(:view_account_login_bottom, :partial => 'hooks/redmine_shibboleth_auth/login_shibboleth_link')
  end
end
