module RedmineShibbolethAuth;
  class Hooks < Redmine::Hook::ViewListener
    def view_account_login_bottom (context={ })
      shibb_enable = Setting.plugin_redmine_shibboleth_auth['enable_shibboleth']
      shibb_handle = Setting.plugin_redmine_shibboleth_auth['shibb_login_handle']

      if (shibb_enable == 'on') && (!shibb_handle.blank?)
        context[:controller].send(:render_to_string, {
          :partial => "hooks/login_shibboleth_link",
          :locals => context
        })
      end 
    end
  end
end
