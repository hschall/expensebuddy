Rails.application.routes.draw do

devise_for :users, controllers: {
  registrations: "users/registrations"
}

  get 'settings/edit'
  get 'settings/update'
  root "dashboard#index"

  get "dashboard", to: "dashboard#index"

  get  "turbo_test",  to: "pages#turbo_test"
  post "turbo_test",  to: "pages#turbo_test_response"

  get  "import", to: "imports#new"
  post "import", to: "imports#create"
  post "import/save", to: "imports#batch_create", as: "save_imported_transactions"

  delete "transactions/delete_all", to: "transactions#destroy_all", as: "delete_all_transactions"
  delete "/balance_payments/delete_all", to: "balance_payments#delete_all", as: :delete_all_balance_payments
  delete 'delete_all_records', to: 'settings#delete_all_records', as: :delete_all_records



  resources :transactions do
  member do
    patch :update_inline
  end

  collection do
    post :save_all  # ✅ this fixes the routing error
    delete :delete_selected
  end
end

  resources :balance_payments, only: [:index] do
  collection do
    delete :destroy_selected
  end
end


  resources :categories

  resources :empresas, only: [:index, :edit, :update, :destroy] do
    collection do
      post :update_all_transaction_categories
      post :import_from_transactions
      post :save_all 
      delete :delete_selected
    end

    member do
      patch :update_inline
    end
  end


resource :settings, only: [:edit, :update]


  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
