class CategoriesController < ApplicationController
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    @category = current_user.categories.new
    @categories = current_user.categories.order(:name)
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "Categoría actualizada."
    else
      render :edit
    end
  end

  def destroy
  @category = current_user.categories.find(params[:id])

  if @category.transactions.exists?
    redirect_to categories_path, alert: "No puedes eliminar esta categoría porque está asociada a transacciones."
  elsif Empresa.exists?(category_id: @category.id)
    redirect_to categories_path, alert: "No puedes eliminar esta categoría porque está asignada a una empresa."
  else
    @category.destroy
    redirect_to categories_path, notice: "Categoría eliminada correctamente."
  end
end


  def create
    @category = current_user.categories.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Categoría creada exitosamente."
    else
      @categories = current_user.categories.order(:name)
      render :index
    end
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
