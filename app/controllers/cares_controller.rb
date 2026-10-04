# The health follow-up of my dog: vaccines, dewormers, flea treatments, vet visits.
class CaresController < ApplicationController
  before_action :require_dog
  before_action :set_care, only: %i[edit update destroy]

  def index
    @cares = current_dog.cares.latest_first
  end

  # A link from the dog page can choose the kind (?kind=dewormer).
  def new
    @care = current_dog.cares.new(kind: params[:kind].presence_in(Care::KINDS.keys), given_on: Date.current)
  end

  def create
    @care = current_dog.cares.new(care_params)
    if @care.save
      redirect_to dog_path(anchor: "sante"), notice: "#{@care.label} enregistré."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @care.update(care_params)
      redirect_to cares_path, notice: "Soin mis à jour."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @care.destroy
    redirect_to cares_path, notice: "Soin supprimé.", status: :see_other
  end

  private

  def set_care
    @care = current_dog.cares.find(params[:id])
  end

  def care_params
    params.require(:care).permit(:kind, :given_on, :next_due_on, :product, :note)
  end
end
