class TransactionsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_transaction, only: %i[edit update destroy]

  def index
    if params[:cycle_month].blank?
      latest_date = current_user.transactions.maximum(:date)

      if latest_date.present?
        cycle_end_day = current_user.setting.cycle_end_day
        if latest_date.day > cycle_end_day
          cycle_start = latest_date.change(day: cycle_end_day + 1)
        else
          cycle_start = (latest_date - 1.month).change(day: cycle_end_day + 1)
        end
        params[:cycle_month] = cycle_start.strftime("%Y-%m")
      else
        # Fallback to current month if no transactions exist
        cycle_start = Date.today.change(day: 7)
        params[:cycle_month] = cycle_start.strftime("%Y-%m")
      end
    end

    @transactions = current_user.transactions

    @transactions = @transactions.where(person: params[:person]) if params[:person].present?
    @transactions = @transactions.where(category_id: params[:category_id]) if params[:category_id].present?
    @transactions = @transactions.where("description LIKE ?", "%#{params[:description]}%") if params[:description].present?

    if params[:cycle_month].present?
      selected_date = Date.strptime(params[:cycle_month], "%Y-%m")
      start_date = selected_date.change(day: 7)
      end_date = (start_date + 1.month).change(day: 6)
      @transactions = @transactions.where(date: start_date..end_date)
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("transactions_table", partial: "transactions/table", locals: { transactions: @transactions })
      end
    end
  end

  def new
  @transaction = current_user.transactions.new
  @categories = current_user.categories.order(:name)
end

def create
  @transaction = current_user.transactions.new(transaction_params)
  if @transaction.save
    redirect_to transactions_path, notice: "Transacción registrada exitosamente."
  else
    @categories = current_user.categories.order(:name)
    render :new
  end
end

def edit
  @categories = current_user.categories.order(:name)
end

def update
  if @transaction.update(transaction_params)
    redirect_to transactions_path, notice: "Transacción actualizada."
  else
    @categories = current_user.categories.order(:name)
    render :edit
  end
end


  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: "Transacción eliminada."
  end

  def destroy_all
    current_user.transactions.delete_all
    redirect_to dashboard_path, notice: "Todas las transacciones fueron eliminadas."
  end

  def delete_selected
    if params[:transaction_ids].present?
      deleted_ids = params[:transaction_ids].map(&:to_i)
      current_user.transactions.where(id: deleted_ids).destroy_all
      redirect_to transactions_path, notice: "Transacciones eliminadas correctamente."
    else
      redirect_to transactions_path, alert: "No seleccionaste ninguna transacción."
    end
  end

  def save_all
    (params[:transactions] || {}).each do |id, attrs|
      tx = current_user.transactions.find_by(id: id)
      next unless tx
      tx.update(person: attrs[:person], category_id: attrs[:category_id])
    end

    respond_to do |format|
      format.html { redirect_to transactions_path, notice: "Transacciones actualizadas correctamente." }
      format.turbo_stream {
        flash.now[:notice] = "Transacciones actualizadas correctamente."
        render turbo_stream: turbo_stream.update("alert", partial: "layouts/alerts")
      }
    end
  end

  def update_inline
    @transaction = current_user.transactions.find(params[:id])

    if @transaction.update(transaction_params)
      respond_to do |format|
        format.js
        format.html { redirect_to transactions_path, notice: "Actualizado" }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(
      :date, :description, :amount, :transaction_type,
      :person, :company_code, :country, :category_id
    )
  end
end
