Rails.application.routes.draw do

  resources :datasets
  resources :deposits
  post '/deposits/:id', to: 'deposits#show'
  post '/datasets/:id', to: 'datasets#show'
  get '/reingest/:id', to: 'deposits#reingest'
  post '/dipuuid', to: 'deposits#dipuuid'

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
    end
  end

  mount Blacklight::Engine => '/'

  #root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  root to: 'deposits#index'

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  devise_for :users
  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

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
