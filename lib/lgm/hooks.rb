module Lgm
  class Hooks < Redmine::Hook::ViewListener
    # This just renders the partial in
    # app/views/hooks/my_plugin/_view_issues_form_details_bottom.rhtml
    # The contents of the context hash is made available as local variables to the partial.
    #
    # Additional context fields
    #   :issue  => the issue this is edited
    #   :f      => the form object to create additional fields
    render_on :view_issues_form_details_bottom,
              :partial => '/hooks/view_issues_form_details_bottom'
    render_on :view_issues_show_details_bottom,
              :partial => '/hooks/view_issues_show_details_bottom'
  end
end
