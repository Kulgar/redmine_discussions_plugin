require File.expand_path('../../test_helper', __FILE__)

class DiscussionsControllerTest < ActionController::TestCase
  fixtures  :projects,
            :users,
            :roles,
            :members,
            :member_roles,
            :enabled_modules

  def setup
    @manager_role  = roles(:roles_001)
    @project       = projects(:projects_001)
    @project.enabled_module_names = [:discussions]
  end

  test "An admin should be able to access project discussions" do
    session[:user_id] = 1
    get :index, params: { project_id: @project.id }

    assert_response :success
    assert_select '#discussions'
  end

  test "An authorized user should be able to access project discussions" do
    @manager_role.add_permission! :view_discussions

    session[:user_id] = 2
    get :index, params: { project_id: @project.id }

    assert_response :success
    assert_select '#discussions'
  end

  test "A user without the right permission shouldn't be able to access project discussions" do
    session[:user_id] = 2
    get :index, params: { project_id: @project.id }

    assert_response 403
  end
end
