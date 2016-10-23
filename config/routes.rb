Rails.application.routes.draw do

  mount Qa::Engine => '/qa'

  resources :home
  root to: 'home#index'

  resources :datasets
  resources :deposits
  # set up a resource for Google Drive API calls, with custom actions
  resources :googledrive, only: [] do
    collection do
      # add a custom action for connecting to google api
      get 'connect'
      # add a custom action to handle oauth2 callback
      get 'oauth2callback'
      # add a custom action for finishing off the connection process
      get 'finish'
    end
  end
  resources :googledrive, only: [:index], defaults: { format: :json }

  post '/deposits/:id', to: 'deposits#show'
  post '/datasets/:id', to: 'datasets#show'
  get '/reingest/:id', to: 'deposits#reingest'
  post '/dipuuid', to: 'deposits#dipuuid'
  # custom route for presenting submission documentation 
  get '/datasets/:id/documentation' => 'datasets#documentation', as: :documentation, :defaults => { :format => :text }

  # update api for archivematica
  scope '/api' do
    scope '/v1' do
      scope '/aip' do
        scope '/:id' do
          # get '/' => 'api_aips#show'
          # post '/'  => 'api_aips#create'
          put '/' => 'api_aips#update'
          # delete '/' => 'api_aips#destroy'
        end
      end
      scope '/dip' do
        scope '/:id' do
          put '/' => 'api_dips#update'
        end
        scope '/:waiting' do
          # post because we need to pass api-key
          post '/' => 'api_dips#waiting'
        end
      end
    end
  end

  devise_for :users

  #   mount Blacklight::Engine => '/'
  #
  #   #root to: "catalog#index"
  #   concern :searchable, Blacklight::Routes::Searchable.new
  #
  #
  #
  #   resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
  #     concerns :searchable
  #   end
  #
  #   devise_for :users
  #   concern :exportable, Blacklight::Routes::Exportable.new
  #
  #   resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
  #     concerns :exportable
  #   end
  #
  #   resources :bookmarks do
  #     concerns :exportable
  #
  #     collection do
  #       delete 'clear'
  #     end
  #   end

  mount BrowseEverything::Engine => '/browse'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
