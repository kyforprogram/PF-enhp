class Users::CategoriesController < ApplicationController
  
  def show
   @category = Category.find(params[:id])
  end
  

end
