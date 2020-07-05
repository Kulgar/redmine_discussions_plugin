require File.expand_path('../../test_helper', __FILE__)

class DiscussionsControllerTest < ActionController::TestCase

  def test_index
    get :index

    assert_response :success
    assert_select '#discussions'
  end
end
