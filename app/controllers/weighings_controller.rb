# The weight of my dog over time.
class WeighingsController < ApplicationController
  before_action :require_dog
  before_action :set_weighing, only: %i[edit update destroy]

  def index
    @weighings = current_dog.weighings.in_order.reverse
  end

  def new
    @weighing = current_dog.weighings.new(measured_on: Date.current)
  end

  def create
    @weighing = current_dog.weighings.new(weighing_params)
    if @weighing.save
      redirect_to dog_path(anchor: "poids"), notice: "Pesée enregistrée."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @weighing.update(weighing_params)
      redirect_to weighings_path, notice: "Pesée mise à jour."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @weighing.destroy
    redirect_to weighings_path, notice: "Pesée supprimée.", status: :see_other
  end

  private

  def set_weighing
    @weighing = current_dog.weighings.find(params[:id])
  end

  def weighing_params
    params.require(:weighing).permit(:measured_on, :weight_kg)
  end
end
