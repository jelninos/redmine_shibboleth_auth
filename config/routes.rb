# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :account do
  collection do
    get 'shibb_error'
    get 'create_shibboleth_authsource'
  end
end
