# Redmine course

## Redmine installation

[Github](https://github.com/redmine/redmine)

```bash
git clone git@github.com:redmine/redmine.git
# or
git clone https://github.com/redmine/redmine.git

cd redmine

# Recommended: switch to the stable branch you want to develop with
git checkout -b 4.1-stable origin/4.1-stable

###
# or with SVN (official redmine SCM)
svn co https://svn.redmine.org/redmine/branches/4.1-stable redmine-4.1
cd redmine-4.1
###

# Once under redmine folder
ruby -v
# Should be >= 2.3 and < 2.7 - swith to a compatible ruby version if needed (rvm use ...)

# Do a bundle install and configure you DB while it is running
bundle install
```

Follow [db install instructions](https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Installation-procedure)
If you want to use sqlite (dev only) skip this step. It is recommended to use the same DB system as the one used in production.

Copy database connection configuration:
`cp config/database.yml.example config/database.yml`

Configure development and test configurations with the database you use.

Follow step 3 in above redmine documentation and replace production with test and development.

For a postgresql db (for instance):

```yaml
# Fichier database.yml:
development:
  adapter: postgresql
  database: redmine_dev
  host: 127.0.0.1
  username: redmine
  password: "redmine"
  encoding: utf8  
​
test:
  adapter: postgresql
  database: redmine_test
  host: 127.0.0.1
  username: redmine
  password: "redmine"
  encoding: utf8  
​```

```bash
# To create the user and dbs:
sudo su postgres
createuser redmine -P
createdb redmine_dev -O redmine
createdb redmine_test -O redmine
```

[Install rmagick](https://github.com/rmagick/rmagick)
Follow instructions according to your OS.

If you get stuck, it isn't that bad... you still will be able to launch redmine. Just continue and get back to that latter. Just install gems without rmagick:

`bundle install --without rmagick`


Generate a random key used to secure cookies storing session data:

`bundle exec rake generate_secret_token`

_note: bundle exec is used to run a command using the gem version from the current folder Gemfile(.lock), especially useful in production if gems are installed within the app folder._

Do the db migration:

`bundle exec rake db:migrate`

Execute the redmine seed that creates default configuration data:

`bundle exec rake redmine:load_default_data`

Select the language you want to use in redmine by default (I used fr for this guide).

Launch app:

`bundle exec rails server webrick`

You should be able to log in with: admin / admin

**In production**

Follow the official [Installation guide](https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Step-6-Database-schema-objects-creation)

Don't forget to also execute any other commands you needed to do for your specific app (like the plugin installation commands we will see in a moment).

## Before we start with the plugin

Create a new project, with the name you want.

Create a new issue (ticket) and assign it to yourself (just to confirm everything is working).

## Plugin

[Official plugin guide](https://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial)

### Goals

We will create a plugin that adds a "discussions" feature to redmine.

Where someone can start a thread with a subject and other users can answer it.

We will add that feature first at the root level of redmine and then we will move it at the project level.

We will create private discussions regarding a specific project and only users that can access that project will be able to access these discussions.

We will also create an API endpoint that will be able to list discussions and answers both in xml and json.

Finally we will create a "generate issue from discussion button" that will redirect the user who clicks that button to the new issue form with content already filled from the discussion.

### Setup

Create a plugin using the redmine generator:

(you can replace Discuss with the name of your plugin)

```bash
bundle exec rails generate redmine_plugin Discuss
```

Have a look at the `plugins/plugin_name` folder.

The `init.rb` file is the entry point, you can edit it right away with your info.

Beware, any plugin generation or changes to init.rb needs you to restart the app.

Restart the server and go to `http://localhost:3000/admin/plugins`

You should now see the installed plugin.

**Important:** Plugins subfolder are gitignored. So you probably should git init your new plugin folder if you want scm activated for it.

**Important:** Installing new plugin from the redmine community isn't harder than what you just did.

Most plugins can be downloaded directly in the plugin folder and should work. Of course, always have a look at plugins readme to see if you need to do anything else. They usually ask you to do some migrations.

Also be careful with compatibility, not all plugins will work with latest redmine version.

In the [plugins directory](https://www.redmine.org/plugins?utf8=%E2%9C%93&page=1&sort=&v=4.1) you can choose the version of redmine in the top right select field.

### Adding a new view

First, we need to create a route to match url.

Plugins are like mini rails app. They have their own routes.rb file in config folder.

Edit it, add a new route:

`get 'discussions', to: 'discussions#index'`

#### Unit tests (if you want to)

We now can do some TDD, plugins have unit tests too.

You can have a look at minitest documentations:
* https://github.com/seattlerb/minitest
* https://guides.rubyonrails.org/testing.html -> better to look at this one

Chapters 2.4 & 2.5 of the Rails guide show you a list of available test assertions.

Looking at redmine unit tests should also help a lot.

To initialize test db (we can chain rails tasks that way):
`rails db:migrate redmine:plugins:migrate redmine:load_default_data RAILS_ENV=test`

To run all tests, just do: `rails test`

And for our plugin (change discuss with your plugin name):

`RAILS_ENV=test bundle exec rails test plugins/discuss/test`

Let's write our first test, and make it red. We want to test a successfull access to "/discussions"

Create the file `discussions_controller_test.rb` under the test folder of your plugin.

The first line of every test file should be:

`require File.expand_path('../../test_helper', __FILE__)`

This loads the test_helper file automatically generated during plugins creation.

This test_helper file has this line:

`require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')`

This loads the redmine test_helper file so that you are running all your plugins tests under the same environment as your redmine application.

You will be able to access redmine fixtures thanks to that.

Now, add the following code to your new test file:

```ruby
class DiscussionsControllerTest < ActionController::TestCase

  def test_index
    get :index

    assert_response :success # expect get response to be a success
    assert_select "#discussions" # expect page rendered by index action to have an html tag with the #discussions id
  end
end
```

Now run test:

`RAILS_ENV=test bundle exec rails test plugins/discuss/test`

It should fail, saying that there is no controller at all.

From now on, it is up to you to create your tests or not. This course will introduce some new info about unit tests here and there when needed.

Don't do too many of them or you won't be able to finish this course.

### Generating the controller

To see all available generators:

`bundle exec rails generate --help`

Get some help:

`bundle exec rails generate redmine_plugin_controller --help`

* _NAME: is the plugin name in this help usage -> Discuss in this course_
* _CONTROLLER: is the controller name -> discussions for this case_

```bash
bundle exec rails generate redmine_plugin_controller Discuss discussions index show new create edit update destroy
```

Remove create, update and destroy views, we don't need these as you already know.

Within the index view, add a simple div:

```html
<div id="discussions">
  <h2>Discussions</h2>
</div>
```

Now your unit test should pass:

`RAILS_ENV=test bundle exec rails test plugins/discuss/test`

And you should be able to access: `http://localhost:3000/discussions`

### Generating the model

**Important:** From now, this guide will let you develop a bit more on your own.
It will provide you some useful line of codes for the tasks you need to do.
If you are really stuck, ask your trainer or look at the final solution.

Our index doesn't display much right now.
So let's create the Discussion model and display a list discussions.

`bundle exec rails generate redmine_plugin_model discuss discussion subject:string content:text priority:belongs_to author:belongs_to project:belongs_to`

Maybe you are wondering, why priority:belongs_to and author:belongs_to? Have a look at the "issue model" under redmine you will see these belongs_to there as well. We will do the exact same thing and reuse what already exists in redmine (issue priority as priority setter for our discussions and user model as author).

We are also adding a belongs_to to project as we want discussions to eventually be linked to projects.

You can run the migration of your plugin(s) with this command:

`bundle exec rake redmine:plugins:migrate`

Don't forget:

`rails -T`

To see all tasks available.

We need to modify the migration a bit. It should look like this:

```ruby
  def change
    create_table :discussions do |t|
      t.string :subject
      t.text :content
      t.integer :author_id, foreign_key: true
      t.integer :priority_id, foreign_key: true
      t.belongs_to :project, foreign_key: true
    end
    add_index :discussions, :priority_id
    add_index :discussions, :author_id
  end
```

We changed t.belongs_to for author and priority because the "belongs_to" keyword automatically checks the existence of the corresponding table in the database.
Here, it would check for the table "authors" and "priorities" which don't exist (the tables are: users and issue_priorities). So we create the foreign_key ourselves with a simple integer column. This also shows you how to add an index to a column.

**Rolling back?** there is no "db:rollback" for plugins. So if you need to rollback you can either do:

```bash
# To revert all plugin migrations (NAME=plugin name):
bundle exec rake redmine:plugins:migrate NAME=discuss VERSION=0

# To revert to a specific migration (VERSION=migration timestamp):
bundle exec rake redmine:plugins:migrate NAME=discuss VERSION=20200705120000

# The above command will run migrations downward up to (but not including it) the specified version
```


Now add the belongs_to association to your Discussion model.
Don't forget the option `optional: true` for the belongs_to project association.

**optional?** Redmine doesn't enforce presence of belongs_to data by default (they deactivated that configuration). But we still put the optional: true, just in case they change that default behavior in the future. You can set `optional: false` (or true) for author and priority if you want/need to.

If you look at the Issue model in Redmine, you'll see the option `class_name` used for some belongs_to. This is a way - for instance - to tell Rails that we are using a foreign_key and an association named "Author" but this foreign_key/association is actually referencing a User data.

Create one (or more) discussion(s) from a rails console and list them by subject in the index page.
To set an author: `discussion.author = User.first`
Now you can get the author using: `discussion.author` and you will get back a User data.

### Playing with menus

We would like our users to access our new discussions index.

We need to change the init.rb file of our plugin to do so.

Add this line:

`menu :application_menu, :discussions, {controller: "discussions", action: "index"}, caption: 'Discussions'`

(don't forget to restart server as we changed the init.rb file of our plugin)

We are adding a "Discussion" button within our application menu. Unfortunately, the init.rb file doesn't know about routes and prefixes (discussions_path). So we have to tell him what action of which controller our now menu button should lead to.

You could have a look at the official plugin guides to see what options the `menu` code accepts.

If you access the main [projects page](http://localhost:3000/projects), you should see the new menu button at the right of the tabs.

### A bit of translations

Replace

`menu :application_menu, :discussions, {controller: "discussions", action: "index"}, caption: 'Discussions'`

With

`menu :application_menu, :discussions, {controller: "discussions", action: "index"}, caption: "discussions.menu".to_sym`

Restart the app and reload the browser.

If we provide a symbol to caption, redmine will try to look for a translation for that menu.
For me, it tries to find fr.discussions.menu. So I'll create a fr.yml file under my plugin config/locales folder and add the translation:

```YAML
fr:
  discussions:
    menu: "Conversations"
    index:
      title: "Conversations"
```

When we create a new locale file, we usually need to restart the app to load it.

I also added a translation for my index file title: `<h2><%= t(".title") %></h2>`

### CRUD/Rest logic

Now... you should be able to write all the code of actions, index, views, etc. on your own.
Finding this hard and very long? Read the bellow info point.

**Info:** unfortunately redmine has no "scaffold" generator.
But you can create a simple rails app (or reuse an app you already have), use the scaffold generator there and copy paste all the files you want from this rails app to your plugin folder.

For instance, this is what can be done for discussions (from another app than redmine!):

`rails g scaffold discussion subject:string content:text project:belongs_to priority:belongs_to author:belongs_to --no-jbuilder --no-scaffold-stylesheet --no-javascripts --no-stylesheets`

I added some "no-..." options to prevent the scaffold from generating files I won't need. Jbuilder isn't used in redmine for its API, so, I deactivated it as well.

Don't forget the --force option if you want to overwrite already generated files.
And don't forget the `resources :discussions` in your routes.rb file of your plugin.

You also have to restart your app if your modify the routes.rb file.

Don't worry if the routes to access discussions no longer work, we will repair that in a moment.

Also, if you copy/paste the model file from the generated code by the scaffold, the model shouldn't inherite from `ApplicationRecord` => that class doesn't exist in redmine. So replace the inheritance with `ActiveRecord::Base`


### Permissions

We want to allow only some specific profiles to access the discussions feature.
Again we can set some configurations in the init.rb file:

```ruby
  permission :view_discussions, discussions: [:show, :index]
  permission :add_discussion, {discussions: [:new, :create, :edit, :update, :destroy]}, require: :member
```

Here we specify which actions are accessible in our discussions controller.
Each permission line above will render a new line within the permission tables in redmine configurations.

Replace the existing menu line so that our discussions tab will now appear in projects menu:

```ruby
  menu :application_menu, :discussions, {controller: "discussions", action: "index"}, caption: "discussions.menu".to_sym
  # with
  menu :project_menu, :discussions, { controller: 'discussions', action: 'index' }, caption: "discussions.menu".to_sym, after: :activity, param: :project_id
```

Restart the app.

You can now set permissions for your plugin here: http://localhost:3000/roles/permissions
You can see that, for the "add discussion" permission we cannot check non members / anonymous. This is because of the require: :member option.

We also added a new option to our project_menu: param: :project_id, so that we can now access project_id params from our discussions controller.

**Important:** the `lib/redmine.rb` file in redmine shows you all the options that may be used for menus and permissions
For instance, as we are developing something similar to forums, there is the `delete_menu_item :project_menu, :boards` method that allows you to remove the forum tab in project menu. Useful if you want to completely overwrite a redmine functionality.

Where did I find the ":boards" name? From the lib/redmine.rb file, under `Redmine::MenuManager.map :project_menu do |menu|` (line 319 in redmine 4.1 stable).

### Filter access

We can now filter access to discussions using the `before_action :authorize` that comes from redmine.
Note that as our discussions are now accessible at the project level only, we have to set the @project BEFORE the authorization filter occurs so that the "authorize" method can check that the user has access to that project before checking if he can access discussions.

We can do that like this:
```ruby
  before_action :set_project
  before_action :authorize
  # or:
  before_action :set_project, :authorize
```

Now that we have the project in our discussions controller, we should filter discussions by project and set project_id:

```ruby
  def index
    @discussions = Discussion.where(project_id: @project.id)
  end

  def create
    @discussion = Discussion.new(discussion_params)
    @discussion.project_id = @project.id
    ...
  end
```

We should also nest discussions within projects in routes to have better URLs:

```ruby
resources :projects do
  resources :discussions
end
```

Don't forget to update all the links in discussion views accordingly. As a reminder:
```ruby
link_to 'Show', discussion
# becomes
link_to 'Show', [@project, discussion]

link_to 'Edit', edit_discussion_path(discussion)
# becomes
link_to 'Edit', edit_project_discussion_path(@project, discussion)

link_to 'Destroy', discussion, method: :delete, data: { confirm: 'Are you sure?' }
# becomes
link_to 'Destroy', [@project, discussion], method: :delete, data: { confirm: 'Are you sure?' }

link_to 'Back', discussions_path
# becomes
link_to 'Back', project_discussions_path(@project)

# and
form_with(model: discussion, local: true) do |form|
# becomes
form_with(model: [@project, discussion], local: true) do |form|
```

### Discussions as module

To transform discussions as a project module that can be enabled/disabled, simply wrap your permissions within a project_module block:

```ruby
  project_module :discussions do
    permission :view_discussions, discussions: [:show, :index]
    permission :add_discussion, {:discussions => [:new, :create, :edit, :update, :destroy]}, :require => :member
  end
```

Restart the app, you should now see the discussions module in your project configuration:

http://localhost:3000/projects/1/settings

### A bit of translations again

You can translate module name and permissions labels like this:

```yaml
fr:
  permission_add_discussion: Créer une conversation
  permission_view_discussions: Accéder aux conversations
  project_module_discussions: Conversations
```

Easy:
* permission + permission_name to translate permissions
* project_module + project_module_name to translate project module name

### Adding has_many :discussions

This is a bit advanced in rails development, so only do that if you feel confortable, skip this part if you aren't.

**Do these two points only if you skip this part:**
* remember to associate discussions to project anyway, when initializing or creating a new discussion with: `discussion.project = @project`
* and filter discussions in index: `discussion.where(project_id: @project.id)`

It is possible to "patch" (add features) to existing redmine core Classes.

For instance we want to add the has_many :discussions association in Project model.
Add this in your init.rb file:

```ruby
# Patches to the Redmine core when this module is loaded.
Rails.configuration.to_prepare do
  # Don't include the same module multiple time (like in tests)
  unless Project.included_modules.include? Discuss::ProjectPatch
    Project.include(Discuss::ProjectPatch)
  end
end
```

Then create the file: `lib/discuss/project_path.rb`
Add this code:

```ruby
module Discuss
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      has_many :discussions, dependent: :destroy
    end
  end
end
```

More about active support concern: https://api.rubyonrails.org/classes/ActiveSupport/Concern.html

Now we can restart the app and use the project.discussions association as we are used to.
We can now do in our index method:

```ruby
  def index
    @discussions = @project.discussions
    ...
  end
```

_note: you won't find a lot of documentations about how to extend core models and controllers. There is this [documentation](https://www.redmine.org/projects/redmine/wiki/Plugin_Internals#Extending-the-Redmine-Core) but is it a bit old.
So, it is better to look at existing up to date plugins. Like [this one](https://github.com/AlphaNodes/additionals/tree/master/lib/additionals/patches) which is doing a lot of patches the right way._

### Generating issue from discussion

There is several ways to do that.

* The first one would be to add a new action in your discussions controller in which you create a new issue and then redirect to the edit page of that issue
* But, looking at issues_controller, we can see a `build_new_issue_from_params` before action. We will use that solution:

Looking at the code of that method in issues controller, we can see these two lines:

```ruby
attrs = (params[:issue] || {}).deep_dup
...
@issue.safe_attributes = attrs
```

`deep_dup` is used to deeply duplicate a hash (if there are hashes in the hash). There we see, the method is copying params from the URL.
And a bit latter, these copied params are assigned to the initialized issue through the safe_attributes method (which is something developed by redmine).

Now looking at these safe attributes in the Issue model (starting line 457 in redmine 4.1), we can see that we can set some fields already.
So for this one, adding this link to in our discussion show view, will work:

```ruby
link_to "Generate issue", new_project_issue_path(@project, discussion_id: @discussion, issue: { description: @discussion.content, subject: @discussion.subject, priority_id: @discussion.priority_id })
```

That way we have a link that redirects us to the issue creation with some fields already filled.

_note: I think you have guessed at this point that you will have to look a lot at the redmine code to develop your own things. Fortunately the redmine code isn't that hard to read and understand_

### Hooks

Redmine has some hooks that allows dev to insert some code here and there in the app.

To see all the hooks available, use one of these three commands:

```bash
grep -r call_hook *                                       # list of source lines with hook calls
grep -rohT 'call_hook([^)]*)'                             # list of hooks calls and source files
grep -roh  'call_hook([^)]*)' | sort -u | grep '([^)]*)'  # list of hooks calls only
```

There is a good example in the [official documentation](https://www.redmine.org/projects/redmine/wiki/Hooks#View-hooks-2) for a view hook. We could use that example to insert a new field in the issues form.

How would you add a new "discussion_id" field to the issue form? And then display in the issue show page a link to that discussion?

This reuse the same "Patch" method as the one used above for projects. So again, rather do the XML View below if you don't feel comfortable enough.

In any case, if you want to, you can have a look at the commit "24e8cd5b6a2a22c1fe54e7a86899fa51d280b21c" for this one.

### XML View

Redmine uses its own code to generate JSON and XML files but there are no documentations about how to use that generator with plugins.

So, two choices here:

* You can either install a custom gem (like rabl) and use that one to generate JSON / XML

For instance, here is a little guide to install rabl in your redmine project:

Add the rabl gem (that will be used to generate xml).
Create a Gemfile file within the root of your plugin and add this line:

```bash
gem "rabl"
```

The Gemfile (or PluginGemfile) files are automatically loaded by redmine when you run bundle install (look at the end of the redmine Gemfile to see how it's done).
Be warned though, plugins are gitignored, so do remember to reinstall your plugin(s) on every redmine installation you do.

* Or you can have a look at the .rsb files in redmine core code and try to reuse the code for your plugin.

The redmine code to generate API views (XML/JSON) isn't that complicated.
So it is really up to you to choose one of these two solutions.

I did the second one for this plugin and you have an example in the repository for the discussions index api view.

To have discussions index respond to api requests, just add the following code:

```ruby
  accept_api_auth :index

  def index
    @discussions = Discussion.all

    respond_to do |format|
      format.html
      format.api
    end
  end
```

accept_api_auth is used by redmine to know which actions in our controller should be accessible through api.

Enable API requests at this url: http://localhost:3000/settings?tab=api

Then go to:
http://localhost:3000/projects/1/discussions.xml
or
http://localhost:3000/projects/1/discussions.json

And enter your login / password.
For now the page renders nothing. Let us create a `index.api.rsb` file in our discussions views folder.
And add this code in it:

```ruby
api.project_discussions do
  api.project(:id => @project.id, :name => @project.name)
  api.array :discussions, api_meta(:total_count => @discussions.size) do
    @discussions.each do |discussion|
      api.discussion do
        api.id               discussion.id
        api.subject          discussion.subject
        api.content          discussion.content
      end
    end
  end
end
```

Refresh, and here you go!
`api.sth` creates a new node / json key in your API, and it can either takes:
* a Block of code to create nested keys (like api.discussion above)
* a value to create a key|node value pair (like api.subject above)
* a hash to create several key|node value pairs (like api.project above)

There is also the `api.array` to generate an array.
You should now be able to add some more info in your API.

**More about redmine API** [can be found here](https://www.redmine.org/projects/redmine/wiki/Rest_api)

_Note: redmine doesn't use any partials in its API, but rabl allow you to use partials in API views. Keep that in mind._


### Answers

We now have our discussions.
But we need to be able to answer them and have a thread.

Here, you are on your own with the following information:

We want to use nested resources:

```ruby
resources :projects do
  resources :discussions do
    resources :answers, except: [:new, :index, :show]
  end
end
```

We don't need index, new and show page as we will display answers directly in the discussion show view.
We will also allow users to create answers from that view, delete one and click on an edit button that will leads to the edit view of the answer.

To display new nested routes:
`rails routes -g discussions`

This is the scaffold that could be used to generate answers CRUD logic from another rails app:

`rails g scaffold answer content:text discussion:belongs_to author:belongs_to --no-jbuilder --no-scaffold-stylesheet --no-javascripts --no-stylesheets`


Don't forget the has_many relationship between discussions and answers:

```ruby
class Discussion < ActiveRecord::Base
  has_many :answers, dependent: :destroy
  ...
end
```

**Info about displaying answers in discussion show view**

You can perfectly transform the index view generated into a partial and render that partial in your discussion view, this is a really nice way to do that.
But let me show you an even better way:

Once you have copied the generated views from the scaffold to your plugin, you should have a `show.html.erb` view.
Rename it to `_answer.html.erb`.

In you discussion show view, add this line wrapped in `<%= ... %>`:

```ruby
render @discussion.answers
```

Rails will understand that it should render the partial named `_answer.html.erg` from the `answers` folder.
And it will iterate automatically on every answer and render the partial for each answer.

Rails also provides the partial with a variable named exactly the same way as the name of the partial.
So in our partial we just need to replace `@answer` by `answer` to make it work.

The partial could now look like this:

```ruby
<% unless answer.new_record? %>
  <div class="answer">
    <p>
      <strong>Content:</strong>
      <%= answer.content %>
    </p>

    <p>
      <strong>Author:</strong>
      <%= answer.author&.name %>
    </p>

    <% if answer.editable? %>
      <%= link_to 'Edit', edit_project_discussion_answer_path(@project, @discussion, answer) %>
    <% end %>
  </div>
<% end %>
<%# %>
```


**Info about setting the author**

Redmine gets the currently logged in user with `User.current`
So we can use that in our controller to set it:

```ruby
  def create
    @answer = @discussion.answers.build(answer_params)
    @answer.author = User.current

    respond_to do |format|
      if @answer.save
      ...
  end
```

It is perfectly fine to send discussion_id and author_id from the form too. You can use the form builder `hidden_field` method for that.
But then you will need to check that the author_id param from your form match the User.current.id value to prevent a user to create an answer for someone else.
So maybe it is better to set the author and discussion directly from the controller actions and it is best to remove these two attributes from permitted parameters (in answer_params method).
Also don't forget to check that the user who edits or delete an answer is the author or an admin.

### Use redmine helpers

Redmine does have some helpers that can be used in your plugin views. One way to do that is to include the helper module you need in one of your plugin helpers. For instance if I want to use method in ProjectsHelper in my plugin, I could create a discussions_helper.rb helper and add this code:

```ruby
module DiscussionsHelper
  include ProjectsHelper
end
```

That way, you can access all the projects helper method from your plugin views (you can't if you don't do that change).
But be careful, the more core stuff you use in your plugins the more time it will take to update your plugin to be compatible with latest redmine versions.

### More unit tests?

You may have noticed that our first unit test we created no longer works because there is now a lot more things to set (project, permissions...). How can we repair it?

We can access redmine fixtures from our unit test files.

As a reminder, fixtures are files that pre-define some data with specific values for each attributes. Unfortunately redmine has no documentations about its fixtures and unit tests, so you would have to look at these files on your own to discover what data are available and which attributes are defined.

For instance, we could use a bunch of fixtures in our discussions controller test:

```ruby
class DiscussionsControllerTest < ActionController::TestCase
  fixtures  :projects,
            :users,
            :roles,
            :members,
            :member_roles,
            :enabled_modules
end
```

This will load some data in my test database usable in each of my unit test.

`members` and `member_roles` are needed to link users to projects and specific roles. How do we know which user has access to what? You have to look at the redmine fixtures.

`enabled_modules` is used to pre-enable some modules in some projects. We won't use it in our unit test, but it is good to know it.

We can also point to a specific fixture, for instance we can use the setup method of minitest to automatically setup some specific data for latter use in our tests:

```ruby
  @manager_role  = roles(:roles_001)
  @project       = projects(:projects_001)
  @project.enabled_module_names = [:discussions]
```

Here we enable our new discussions module in the projets 001 (that comes from redmine fixtures).

Now we can repair our test:

```ruby
  test "An admin should be able to access project discussions" do
    session[:user_id] = 1
    get :index, params: { project_id: @project.id }
    assert_response :success
    assert_select '#discussions'
  end
```

* `assert_response` allows us to check the response status from rails app.
* `asset_select` tries to search for a specific css selector in the rendered view

We can also try to check a forbidden access with: `assert_response 403`

**Important** in order to act as an authenticated user, we have - with redmine - to specify the `session[:user_id]` value with the id of the user we want to authenticate. Here, user with id 1 is an admin (look at redmine fixtures - again).

So, our `get :index...` above, will do a get request to the index action of our discussions controller authenticated as user 1 and with project set to 1.

It finds that controller thanks to name conventions for in mini test DiscussionsControllerTest class.

A good exercice would be to create these two new tests:

```ruby
test "An authorized user should be able to access project discussions" do
  # ...
end

test "A user without the right permission shouldn't be able to access project discussions" do
  # ...
end
```

## About generators (rails/rake tasks)

From the beginning of this course, we are using what Rails dev name rails/rake tasks to generate some code and do some migrations for our plugin.

But what are these exactly?

rake/rails tasks (usually named rake tasks) allow users to execute specific actions from an app code. These tasks are usually put in a `lib/tasks` folder.

You can see that redmine does have this folder. You could see all the plugins tasks we used within the redmine.rake file in that folder.

This can be useful to debug commands that don't work and/or look at the options they accept.

The syntax is easy to understand:

```ruby
namespace :redmine do
  ...
  namespace :plugins do
    desc 'Migrates installed plugins.'
    task :migrate => :environment do
      name = ENV['NAME']
      ...
    end
  end
end
```

This task, for instance, will allow use to use the following command in our shell:

```bash
rake redmine:plugins:migrate NAME=discuss
```

* The `namespace` keyword is a way to encapsulate rake tasks so that we don't overwrite, by mistake, an existing rake task from another library
* As you can see we can nest as many namespaces as we want, in the command line, each namespace have to be specified and are separated using `:`
* The `desc` keyword is a way to provide a quick description of the task (what it does), this is something you see when you do `rake -T` to list all the available tasks
* The `task` key word is the actual task (plain ruby code) that will be executed
* Notice the `=> :environment`, this is to tell the rake task: hey! Load my current app environment. Without that, you wouldn't be able to use rails app stuff from the task (like models, libraries...), you would only have access to plain ruby code (like when you use the `irb` console)
* And finally, the `ENV['NAME']` is one of the many way to accept some options from the command line

rake tasks are used a lot for rails web apps, some tasks can be ran during deployment process, others can be ran with linux cronjobs... they provide an easy way to do some specific regular tasks (hence the name tasks) while keeping the code to run these tasks maintenable.

_note: ENV['NAME'] isn't the best way to get options from the command line, actually... the NAME env variable is sometimes used to store the hostname of your server, for instance... So... see a better way bellow_

If you would like to write your own rake tasks (in your plugin for instance), you could do:

```ruby
namespace :discuss do
  desc "Creates x discussions for your first project, create a project if non exists. 'x' can be set as a rake option (rake discuss:generate_discussions[4]"
  task :generate_discussions, [:number, :author_id] => :environment do |task, args|
    project = Project.first
    project ||= Project.create(name: "Project with sample discussions")

    if args[:author_id].present?
      user = User.find(args[:author_id])
    else
      user = User.first
    end

    args[:number].to_i.times do |i|
      discussion = project.discussions.create(subject: "Discussion #{i}", author_id: user.id)
      if discussion.errors.any?
        p discussion.errors.full_messages
        raise "Errors while saving discussion, look at above errors"
      end
    end

    puts "Successfully generated #{args[:number]} discussions"
  end
end
```

Then you could do:

```bash
# rake or rails
rails discuss:generate_discussions[4,1]
```

This will generate 4 discussions with the user with id 1 as the author.

_note: User.find will raise a ActiveRecord::RecordNotFound if the user with the specified id doesn't exist, so we are good with that. Also don't put any spaces in rake tasks arguments within [], otherwise it won't work_
