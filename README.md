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
(Follow step 3 in above redmine documentation and replace production with test and development)

[Install rmagick](https://github.com/rmagick/rmagick)
Follow instructions according to your OS.
If you get stuck, it isn't that bad... you still will be able to launch redmine. Just continue and get back to that latter.


Generate a random key used to secure cookies storing session data:
`bundle exec rake generate_secret_token`

_note: bundle exec is used to run a command using the gem version from the current folder Gemfile(.lock), especially useful in production if gems are installed within the app folder._

Do the db migration:
`bundle exec rake db:migrate`

Execute the redmine seed that create default configuration data:
`bundle exec rake redmine:load_default_data`

Select the language you want to use in redmine by default

Launch app:
`bundle exec rails server webrick`

You should be able to log in with: admin / admin

**In production**

Follow the official [Installation guide](https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Step-6-Database-schema-objects-creation)

Don't forget to also execute any other commands you needed to do to install things you need (like the Gemfile.local).

## Before we start with the plugin

Create a new project, with the name you want.
Create a new issue (ticket) and assign it to yourself (just to confirm everything is working).

## Plugin

[Official plugin guide](https://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial)

### Goals

We will create a plugin that adds a "discussions" feature to redmine.
Where someone can start a thread with a subject and other users can answer it.

We will add that feature both at the root level and project level of redmine.
Root level will be generic discussions.

Project level will be private discussions regarding a specific project and only users that can access that project will be able to access these discussions.

We will also create an API endpoint that will be able to list discussions and answers both in xml and json.

Finally we will create a "generate issue from discussion button" that will send the use who clicks that button to the new issue form with content already filled with the main subject extracted from the discussion.

### Setup

Create a plugin using the redmine generator:
(you can replace Lgm with the name of your plugin)

```bash
bundle exec rails generate redmine_plugin Lgm
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

And for our plugin (change lgm with your plugin name):

`RAILS_ENV=test bundle exec rails test plugins/lgm/test`

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

`RAILS_ENV=test bundle exec rails test plugins/lgm/test`

It should fail, saying that there is no controller at all.

From now on, it is up to you to create your tests or not. This course will introduce some new info about unit tests here and there when needed.
Don't do too many of them or you won't be able to finish this course.

### Generating the controller

To see all available generators:

`bundle exec rails generate --help`

Get some help:

`bundle exec rails generate redmine_plugin_controller --help`

* _NAME: is the plugin name in this help usage -> Lgm in this course_
* _CONTROLLER: is the controller name -> discussions for this case_

`bundle exec rails generate redmine_plugin_controller Lgm discussions index show new create edit update destroy`

Remove create, update and destroy views, we don't need these as you already know.

Within the index view, add a simple div:

```html
<div id="discussions">
  <h2>Discussions</h2>
</div>
```

Now your unit test should pass:

`RAILS_ENV=test bundle exec rails test plugins/lgm/test`

And you should be able to access: `http://localhost:3000/discussions`

### Generating the model

**Important:** From now, this guide will let you develop a bit more on your own.
It will provide you some useful line of codes for the tasks you need to do.
If you are really stuck, ask your trainer or look at the final solution.

Our index doesn't display much right now.
So let's create the Discussion model and display a list discussions.

`bundle exec rails generate redmine_plugin_model lgm discussion subject:string content:text priority:belongs_to author:belongs_to project:belongs_to`

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
```
# To revert all plugin migrations (NAME=plugin name):
bundle exec rake redmine:plugins:migrate NAME=lgm VERSION=0

# To revert to a specific migration (VERSION=migration timestamp):
bundle exec rake redmine:plugins:migrate NAME=lgm VERSION=20200705120000

# The above command will run migrations downward up to (but not including it) the specified version
```


Now add the belongs_to association to your Discussion model.
Don't forget the option `optional: true` for the belongs_to project association.

**optional?** Redmine doesn't enforce presence of belongs_to data by default (they deactivated that configuration). But we still put the optional: true, just in case they change that default behavior in the future. You can set `optional: false` (or true) for author and priority if you want/need to.

If you look at the Issue model in Redmine, you'll see the option `class_name` used for some belongs_to. This is a way - for instance - to tell Rails that we are using a foreign_key named "Author" but this foreign_key is actually referencing a User data.

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
But you can create a simple rails app (or reuse lgm_redmine app), use the scaffold generator there and copy paste all the files you want from this rails app to your plugin folder.

For instance, this is what can be done for discussions:

`rails g scaffold discussion subject:string content:text project:belongs_to priority:belongs_to author:belongs_to --no-jbuilder --no-scaffold-stylesheet --no-javascripts --no-stylesheets`

I added some "no-..." options to prevent the scaffold from generating files I won't need. Jbuilder isn't used in redmine for its API, so, I deactivated it as well.

Don't forget the --force option if you want to overwrite already generated files.
And don't forget the `resources :discussions` in your routes.rb file of your plugin.

You also have to restart your app if your modify the routes.rb file.

### Answers

We now have our discussions.
But we need to be able to answer them and have a thread.

Here, you are on your own with the following information:

We want to use nested resources:

```ruby
resources :discussions do
  resources :answers, except: [:new, :create, :index, :show]
end
```

We don't need index, new and show page as we will display answers directly in the discussion show view.
We will also allow users to create answers from that view, delete one and click on an edit button that will leads to the edit view of the answer.

This is the scaffold that could be used to generate answers CRUD logic from another rails app:

`rails g scaffold answer content:text discussion:belongs_to author:belongs_to --no-jbuilder --no-scaffold-stylesheet --no-javascripts --no-stylesheets`

_note: you can perfectly transform the index view generated into a partial and render that partial in your discussion view, this is a really nice way to do that_

Don't forget the has_many relationship between discussions and answers:

```ruby
class Discussion < ActiveRecord::Base
  has_many :answers, dependent: :destroy
  ...
end
```


We also want to add a menu button in our projects:
