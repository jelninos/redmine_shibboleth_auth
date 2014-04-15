module ShibbolethAuthHelper
  unloadable

  def get_attribute_value(attribute_name)
    header_attr_name = "header_" + attribute_name
    conf = Setting.plugin_redmine_shibboleth_auth
    
    if conf.has_key?(header_attr_name)
      request.env[conf[header_attr_name]]
    else
      nil
    end
  end
end
