module OmniauthCallbacksHelper
  def sign_in_user(authentication)
    sign_in_and_redirect Employee.find(authentication.employee_id)
  end

  def add_new_oauth(_authentication, omni)
    token = omni['credentials'].token
    token_secret = omni['credentials'].secret
    current_user.authentications.create!(
      provider: omni['provider'],
      uid: omni['uid'],
      token: token,
      token_secret: token_secret
    )
    sign_in_and_redirect current_user
  end

  def login_with_matching_data(omni)
    employee = find_employee(omni)
    if employee
      sign_in_and_redirect employee
    else
      redirect_to new_employee_session_path
    end
  end

  private

  def find_employee(omni)
    provider = omni['provider']
    fields = {}
    Settings.dig(:auth, provider, :fields).each_pair do |key, path|
      value = omni.dig(*path)
      fields[key] = value if value
    end
    Employee.find_by(fields)
  end

  # def after_sign_in_path_for(employee)
  #   employee_path(employee)
  # end
end
