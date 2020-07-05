Redmine::Plugin.register :lgm do
  name 'Lgm plugin'
  author 'Régis'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  project_module :discussions do
    permission :view_discussions, discussions: [:show, :index]
    permission :add_discussion, {:discussions => [:new, :create, :edit, :update, :destroy]}, :require => :member
  end

  delete_menu_item :project_menu, :boards

  menu :project_menu, :discussions, { controller: 'discussions', action: 'index' }, caption: "discussions.menu".to_sym, after: :activity, param: :project_id
end
