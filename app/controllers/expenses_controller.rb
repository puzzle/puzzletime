# frozen_string_literal: true

class ExpensesController < ManageController
  include Filterable
  self.optional_nesting = [Employee]

  self.permitted_attrs = %i[payment_date employee_id kind order_id description amount receipt]
  self.remember_params += %w[status employee_id reimbursement_date department_id]

  before_render_index :populate_management_filter_selects, unless: :parent
  before_render_index :populate_employee_filter_selects, if: :parent
  before_render_form :populate_orders
  before_action :set_payment_date, only: :index, if: :parent

  before_save :attach_resized_receipt

  def index
    if parent
      respond_to do |format|
        format.any
        format.pdf { send_file Expenses::PdfExport.new(entries).generate, disposition: :inline }
      end
    else
      redirect_to('/expenses_reviews')
    end
  end

  def new
    entry.attributes = template_attributes
  end

  def update
    with_protected_approved_state do
      options = params[:review] ? { location: expenses_review_path(entry) } : {}
      super(options)

      if entry.rejected? && entry.employee == current_user
        entry.submission_date = Time.zone.today
        entry.pending!
      end
    end
  end

  def destroy
    with_protected_approved_state { super }
  end

  private

  def with_protected_approved_state
    return yield unless entry.approved? && !current_user.management?

    redirect_to employee_expenses_path(current_user), alert: 'Freigegebene Spesen können nicht verändert werden.'
  end

  def list_entries
    entries = parent ? super.includes(:reviewer) : super.joins(:employee).includes(:employee, :reviewer)
    entries = filter_entries_by(entries, :status, :employee_id)
    entries = filter_by_date(entries, :reimbursement_date, :all_month, /(\d{4})_(\d{2})/)
    entries = filter_by_date(entries, :payment_date, :all_year, /(\d{4})/)
    filter_by_department(entries)
  end

  def filter_by_date(scope, key, date_method, regex)
    return scope unless regex.match(params[key])

    year, month = *Regexp.last_match.captures.collect(&:to_i)
    scope.where(key => Date.new(year, month || 1, 1).send(date_method))
  end

  def filter_by_department(scope)
    return scope if params[:department_id].blank?

    scope.where(employees: { department_id: params[:department_id] })
  end

  def populate_management_filter_selects
    @employees = Employee.joins(:expenses).list.uniq
    @departments = Department.list.joins(:employees).where(employees: { id: @employees }).uniq
    @statuses = Expense.statuses.collect { |key, value| IdValue.new(value, Expense.status_value(key)) }
    @kinds = Expense.kinds.collect { |key, value| IdValue.new(value, Expense.kind_value(key)) }
    @months = Expense.reimbursement_months.sort.reverse.collect do |date|
      IdValue.new(I18n.l(date, format: '%Y_%m'), I18n.l(date, format: '%B, %Y'))
    end
    @filtered_expenses = list_entries.except(:limit, :offset).pluck(:id)
  end

  def populate_employee_filter_selects
    @years = Expense.payment_years(parent).sort.reverse.collect do |date|
      IdValue.new(I18n.l(date, format: '%Y'), I18n.l(date, format: '%Y'))
    end
  end

  def set_payment_date
    params[:payment_date] ||= list_entries.maximum(:payment_date)&.year.to_s
  end

  def populate_orders
    @orders = Order.list.open.collect { |o| IdValue.new(o.id, o.label_with_workitem_path) }
  end

  def authorize_class
    authorize!(:new, Expense.new(employee: parent))
  end

  def template_attributes
    attrs = Expense.find_by(id: params[:template])&.attributes || {}
    attrs.slice('kind', 'amount', 'payment_date', 'description', 'order_id')
  end

  def model_params
    # remove receipt param to prevent processing of original image (will get attached in #attach_resized_receipt)
    super.except('receipt')
  end

  def receipt_param
    params.dig(model_identifier, :receipt)
  end

  def pdf_pages_amount(filepath_pdf)
    first_page = Vips::Image.new_from_file(filepath_pdf, page: 0, n: 1)
    first_page.get('n-pages')
  end

  def get_pdf_pages_as_images(filepath_pdf)
    images = []
    total_pages = pdf_pages_amount(filepath_pdf)
    (0...total_pages).each do |page_num|
      image = Vips::Image.new_from_file(filepath_pdf, page: page_num)
      image = image.thumbnail_image(Settings.expenses.receipt.max_pixel)
      images << image
    end
    images
  end

  def combine_images(images, rows, columns)
    rows_of_images = []
    (0...rows).each do |row_num|
      start_index = row_num * columns
      row_images = images[start_index, columns] || []
      # Ensure all rows are the same length by padding with blank images (if necessary)
      row_images += [Vips::Image.black(images.first.width, images.first.height)] * (columns - row_images.size)

      row_image = row_images.reduce { |a, b| a.join(b, :horizontal) }
      rows_of_images << row_image
    end

    rows_of_images.reduce { |a, b| a.join(b, :vertical) }
  end

  def attach_resized_receipt
    return unless receipt_param

    if receipt_param.content_type == 'application/pdf'
      pdf_path = receipt_param.tempfile.path
      images = get_pdf_pages_as_images(pdf_path)
      basename = File.basename(receipt_param.original_filename.to_s, '.*')

      # Calculate the number of rows and columns to fit all images in a square grid
      total_pages = pdf_pages_amount(pdf_path)
      grid_size = Math.sqrt(total_pages).ceil
      rows = grid_size
      columns = (total_pages.to_f / grid_size).ceil

      combined_image = combine_images(images, rows, columns)

      output_path = Rails.root.join('tmp', "#{basename}.jpg")
      combined_image.write_to_file(output_path.to_s, Q: Settings.expenses.receipt.quality)

      entry.receipt.attach(io: File.open(output_path), filename: "#{basename}.jpg", content_type: 'image/jpeg')
    else
      resized = ImageProcessing::Vips
                .source(receipt_param.tempfile)
                .resize_to_limit(Settings.expenses.receipt.max_pixel, Settings.expenses.receipt.max_pixel)
                .saver(quality: Settings.expenses.receipt.quality)
                .convert('jpg')
                .loader(page: 0)
                .call

      target_filename = "#{File.basename(receipt_param.original_filename.to_s, '.*')}.jpg"

      entry.receipt.attach(io: File.open(resized), filename: target_filename, content_type: 'image/jpeg')
    end
  end
end
