Redmine::Plugin.register :lgm do
  name 'Lgm plugin'
  author 'Régis'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  menu :application_menu, :discussions, {controller: "discussions", action: "index"}, caption: "discussions.menu".to_sym

  permission :polls, { polls: [:index, :vote] }, public: true
  menu :project_menu, :discussions, { controller: 'discussions', action: 'index' }, caption: 'Discussions', after: :activity, param: :project_id
end
