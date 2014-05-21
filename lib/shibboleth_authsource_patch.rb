module ShibbolethAuthSourcePatch

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      # override the 'login' action (account controller)
      # alias_method_chain allow use of login_with_shibboleth and login_without_shibboleth methods
      #alias_method_chain :login, :shibboleth
     
      # add shibboleth helper (in lib directory of this plugin) 
      #helper :shibboleth_auth
      #include ShibbolethAuthHelper
    end
  end

  module InstanceMethods
    def create_shibboleth_authsource
      logger.info('YOOOO')
      if false
      @auth_source = AuthSource.new_subclass_instance(params[:type], params[:auth_source])
      if @auth_source.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to auth_sources_path
      else
        render :action => 'new'
      end
      end
    end
  end

end

