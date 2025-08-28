# config/routes.rb
Rails.application.routes.draw do
  # Autenticación
  root   'sessions#new'
  get    'login',             to: 'sessions#new'
  post   'login',             to: 'sessions#create'
  delete 'logout',            to: 'sessions#destroy', as: :logout

  # Ticket de stats post-logout (público)
  get    'post_logout_stats', to: 'sessions#post_logout_stats', as: :post_logout_stats

  # AJAX: comprobar rol
  get    'login/check_role',  to: 'sessions#check_role', as: :check_role

  # Finanzas
  get    'finance', to: 'finance#index', as: :finance

  # Gym Control & E-commerce
  get    'ecommerce',                  to: 'ecommerce#index',            as: :ecommerce
  post   'ecommerce/add_to_cart',      to: 'ecommerce#add_to_cart',      as: :add_to_cart
  delete 'ecommerce/remove_from_cart', to: 'ecommerce#remove_from_cart', as: :remove_from_cart

  # Reportes / Corte (HTML/CSV/XLSX)
  get    'ecommerce/stats(.:format)',  to: 'ecommerce#stats',            as: :stats

  # Productos
  resources :products, only: [:edit, :update, :destroy]

  # Backoffice (SUPERUSUARIO)
  namespace :backoffice do
    root to: 'products#index'
    resources :products
    resources :staff_users
  end
  get 'backoffice', to: 'backoffice/products#index', as: :backoffice

  # Clientes, Membresías e Órdenes
  resources :customers do
    resources :memberships, only: [:index]
  end

  # Órdenes (checkout JSON)
  resources :orders, only: [:create], defaults: { format: :json }

  # Clases
  resources :payments,    only: [:index, :new, :create]
  resources :class_types, only: [:index]
  post 'class_types/checkout', to: 'class_types#checkout', as: :class_checkout

  # Resumen de sesión
  get 'session_summary', to: 'sessions#summary', as: :session_summary
end

