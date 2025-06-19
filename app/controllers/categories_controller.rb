class CategoriesController < ApplicationController
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = Category.order(:name)
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Categoría creada exitosamente."
    else
      @categories = Category.all
      render :index
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: " Categoría actualizada."
    else
      render :edit
    end
  end

  def destroy
  category = Category.find(params[:id])

  if Transaction.exists?(category_id: category.id) || Empresa.exists?(category_id: category.id)
    redirect_to categories_path, notice: "No se puede eliminar la categoría porque está en uso."
  else
    category.destroy
    redirect_to categories_path, notice: "Categoría eliminada."
  end
end


  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
