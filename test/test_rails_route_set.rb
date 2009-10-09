require 'abstract_unit'
require 'action_controller'

ActionController::Routing.generate_best_match = false

module RailsRouteSetTests
  module UriReservedCharacters
    SAFE   = %w( : @ & = + $ , ; ).freeze
    UNSAFE = %w( ^ / ? # [ ] ).freeze

    HEX = UNSAFE.map { |char| '%' + char.unpack('H2').first.upcase }.freeze

    SEGMENT = "#{SAFE.join}#{UNSAFE.join}".freeze
    ESCAPED = "#{SAFE.join}#{HEX.join}".freeze
  end

  Model = Struct.new(:to_param)

  Mapping = lambda { |map|
    map.namespace :admin do |admin|
      admin.resources :users
    end

    map.namespace 'api' do |api|
      api.root :controller => 'users'
    end

    map.connect 'blog/:year/:month/:day',
                :controller => 'posts',
                :action => 'show_date',
                :requirements => { :year => /(19|20)\d\d/, :month => /[01]?\d/, :day => /[0-3]?\d/},
                :day => nil,
                :month => nil

    map.resources :people
    map.connect 'legacy/people', :controller => 'people', :action => 'index', :legacy => 'true'

    map.project 'projects/:project_id', :controller => 'project'

    map.connect '', :controller => 'news', :format => nil
    map.connect 'news.:format', :controller => 'news'

    map.connect 'ws/:controller/:action/:id', :ws => true
    map.connect 'account/:action', :controller => :account, :action => :subscription
    map.connect 'pages/:page_id/:controller/:action/:id'
    map.connect ':controller/ping', :action => 'ping'
    map.connect ':controller/:action/:id'
  }

  def setup
    ActionController::Routing.use_controllers! ['admin/posts', 'posts', 'news', 'notes', 'project']
    @routes = ActionController::Routing::RouteSet.new
    @routes.draw(&Mapping)
    assert_loaded!
  end

  def assert_loaded!
    raise NotImplemented
  end

  def test_recognize_path
    assert_equal({:controller => 'admin/users', :action => 'index'}, @routes.recognize_path('/admin/users', :method => :get))
    assert_equal({:controller => 'admin/users', :action => 'create'}, @routes.recognize_path('/admin/users', :method => :post))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users', :method => :put) }
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users', :method => :delete) }
    assert_equal({:controller => 'admin/users', :action => 'new'}, @routes.recognize_path('/admin/users/new', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users/new', :method => :post) }
    assert_equal({:controller => 'admin/users', :action => 'show', :id => '1'}, @routes.recognize_path('/admin/users/1', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users/1', :method => :post) }
    assert_equal({:controller => 'admin/users', :action => 'update', :id => '1'}, @routes.recognize_path('/admin/users/1', :method => :put))
    assert_equal({:controller => 'admin/users', :action => 'destroy', :id => '1'}, @routes.recognize_path('/admin/users/1', :method => :delete))
    assert_equal({:controller => 'admin/users', :action => 'edit', :id => '1'}, @routes.recognize_path('/admin/users/1/edit', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/admin/users/1/edit', :method => :post) }

    assert_equal({:controller => 'admin/posts', :action => 'index'}, @routes.recognize_path('/admin/posts', :method => :get))
    assert_equal({:controller => 'admin/posts', :action => 'new'}, @routes.recognize_path('/admin/posts/new', :method => :get))

    assert_equal({:controller => 'api/users', :action => 'index'}, @routes.recognize_path('/api', :method => :get))
    assert_equal({:controller => 'api/users', :action => 'index'}, @routes.recognize_path('/api/', :method => :get))

    assert_equal({:controller => 'posts', :action => 'show_date', :year => '2009'}, @routes.recognize_path('/blog/2009', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show_date', :year => '2009', :month => '01'}, @routes.recognize_path('/blog/2009/01', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show_date', :year => '2009', :month => '01', :day => '01'}, @routes.recognize_path('/blog/2009/01/01', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/blog/123456789', :method => :get) }

    assert_equal({:controller => 'people', :action => 'index'}, @routes.recognize_path('/people', :method => :get))
    assert_equal({:controller => 'people', :action => 'index', :format => 'xml'}, @routes.recognize_path('/people.xml', :method => :get))
    assert_equal({:controller => 'people', :action => 'create'}, @routes.recognize_path('/people', :method => :post))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people', :method => :put) }
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people', :method => :delete) }
    assert_equal({:controller => 'people', :action => 'new'}, @routes.recognize_path('/people/new', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people/new', :method => :post) }
    assert_equal({:controller => 'people', :action => 'show', :id => '1'}, @routes.recognize_path('/people/1', :method => :get))
    assert_equal({:controller => 'people', :action => 'show', :id => '1', :format => 'xml'}, @routes.recognize_path('/people/1.xml', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people/1', :method => :post) }
    assert_equal({:controller => 'people', :action => 'update', :id => '1'}, @routes.recognize_path('/people/1', :method => :put))
    assert_equal({:controller => 'people', :action => 'destroy', :id => '1'}, @routes.recognize_path('/people/1', :method => :delete))
    assert_equal({:controller => 'people', :action => 'edit', :id => '1'}, @routes.recognize_path('/people/1/edit', :method => :get))
    assert_equal({:controller => 'people', :action => 'edit', :id => '1', :format => 'xml'}, @routes.recognize_path('/people/1/edit.xml', :method => :get))
    assert_raise(ActionController::ActionControllerError) { @routes.recognize_path('/people/1/edit', :method => :post) }
    assert_raise(ActionController::MethodNotAllowed) { @routes.recognize_path('/people/new', :method => :post) }

    assert_equal({:controller => 'posts', :action => 'show', :id => '1', :ws => true}, @routes.recognize_path('/ws/posts/show/1', :method => :get))
    assert_equal({:controller => 'posts', :action => 'list', :ws => true}, @routes.recognize_path('/ws/posts/list', :method => :get))
    assert_equal({:controller => 'posts', :action => 'index', :ws => true}, @routes.recognize_path('/ws/posts', :method => :get))

    assert_equal({:controller => 'account', :action => 'subscription'}, @routes.recognize_path('/account', :method => :get))
    assert_equal({:controller => 'account', :action => 'subscription'}, @routes.recognize_path('/account/subscription', :method => :get))
    assert_equal({:controller => 'account', :action => 'billing'}, @routes.recognize_path('/account/billing', :method => :get))

    assert_equal({:page_id => '1', :controller => 'notes', :action => 'index'}, @routes.recognize_path('/pages/1/notes', :method => :get))
    assert_equal({:page_id => '1', :controller => 'notes', :action => 'list'}, @routes.recognize_path('/pages/1/notes/list', :method => :get))
    assert_equal({:page_id => '1', :controller => 'notes', :action => 'show', :id => '2'}, @routes.recognize_path('/pages/1/notes/show/2', :method => :get))

    assert_equal({:controller => 'posts', :action => 'ping'}, @routes.recognize_path('/posts/ping', :method => :get))
    assert_equal({:controller => 'posts', :action => 'index'}, @routes.recognize_path('/posts', :method => :get))
    assert_equal({:controller => 'posts', :action => 'index'}, @routes.recognize_path('/posts/index', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show'}, @routes.recognize_path('/posts/show', :method => :get))
    assert_equal({:controller => 'posts', :action => 'show', :id => '1'}, @routes.recognize_path('/posts/show/1', :method => :get))
    assert_equal({:controller => 'posts', :action => 'create'}, @routes.recognize_path('/posts/create', :method => :post))

    assert_equal({:controller => 'news', :action => 'index', :format => nil}, @routes.recognize_path('/', :method => :get))
    assert_equal({:controller => 'news', :action => 'index', :format => 'rss'}, @routes.recognize_path('/news.rss', :method => :get))

    assert_equal({:controller => 'posts', :action => "act#{UriReservedCharacters::SEGMENT}ion"}, @routes.recognize_path("/posts/act#{UriReservedCharacters::ESCAPED}ion"))

    assert_raise(ActionController::RoutingError) { @routes.recognize_path('/none', :method => :get) }
  end

  def test_generate
    assert_equal '/admin/users', @routes.generate(:use_route => 'admin_users')
    assert_equal '/admin/users', @routes.generate(:controller => 'admin/users')
    assert_equal '/admin/users', @routes.generate(:controller => 'admin/users', :action => 'index')
    assert_equal '/admin/users', @routes.generate({:action => 'index'}, {:controller => 'admin/users'})
    assert_equal '/admin/users', @routes.generate({:controller => 'users', :action => 'index'}, {:controller => 'admin/accounts'})
    assert_equal '/people', @routes.generate({:controller => '/people', :action => 'index'}, {:controller => 'admin/accounts'})

    assert_equal '/admin/posts', @routes.generate({:controller => 'admin/posts'})
    assert_equal '/admin/posts/new', @routes.generate({:controller => 'admin/posts', :action => 'new'})

    assert_equal '/blog/2009', @routes.generate(:controller => 'posts', :action => 'show_date', :year => 2009)
    assert_equal '/blog/2009/1', @routes.generate(:controller => 'posts', :action => 'show_date', :year => 2009, :month => 1)
    assert_equal '/blog/2009/1/1', @routes.generate(:controller => 'posts', :action => 'show_date', :year => 2009, :month => 1, :day => 1)

    assert_equal '/people', @routes.generate(:use_route => 'people')
    assert_equal '/people', @routes.generate(:use_route => 'people', :controller => 'people', :action => 'index')
    assert_equal '/people.xml', @routes.generate(:use_route => 'people', :controller => 'people', :action => 'index', :format => 'xml')
    assert_equal '/people', @routes.generate({:use_route => 'people', :controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'index'})
    assert_equal '/people', @routes.generate(:controller => 'people')
    assert_equal '/people', @routes.generate(:controller => 'people', :action => 'index')
    assert_equal '/people', @routes.generate({:action => 'index'}, {:controller => 'people'})
    assert_equal '/people', @routes.generate({:action => 'index'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people', @routes.generate({:controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people/new', @routes.generate(:use_route => 'new_person')
    assert_equal '/people/new', @routes.generate(:controller => 'people', :action => 'new')
    assert_equal '/people/1', @routes.generate(:use_route => 'person', :id => '1')
    assert_equal '/people/1', @routes.generate(:controller => 'people', :action => 'show', :id => '1')
    assert_equal '/people/1.xml', @routes.generate(:controller => 'people', :action => 'show', :id => '1', :format => 'xml')
    assert_equal '/people/1', @routes.generate(:controller => 'people', :action => 'show', :id => 1)
    assert_equal '/people/1', @routes.generate(:controller => 'people', :action => 'show', :id => Model.new('1'))
    assert_equal '/people/1', @routes.generate({:action => 'show', :id => '1'}, {:controller => 'people', :action => 'index'})
    assert_equal '/people/1', @routes.generate({:action => 'show', :id => 1}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people', @routes.generate({:controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'index', :id => '1'})
    assert_equal '/people', @routes.generate({:controller => 'people', :action => 'index'}, {:controller => 'people', :action => 'show', :id => '1'})
    assert_equal '/people/1/edit', @routes.generate(:controller => 'people', :action => 'edit', :id => '1')
    assert_equal '/people/1/edit.xml', @routes.generate(:controller => 'people', :action => 'edit', :id => '1', :format => 'xml')
    assert_equal '/people/1/edit', @routes.generate(:use_route => 'edit_person', :id => '1')
    assert_equal '/people/1?legacy=true', @routes.generate(:controller => 'people', :action => 'show', :id => '1', :legacy => 'true')
    assert_equal '/people?legacy=true', @routes.generate(:controller => 'people', :action => 'index', :legacy => 'true')

    assert_equal '/project', @routes.generate({:controller => 'project', :action => 'index'})
    assert_equal '/projects/1', @routes.generate({:controller => 'project', :action => 'index', :project_id => '1'})
    assert_equal '/projects/1', @routes.generate({:controller => 'project', :action => 'index'}, {:project_id => '1'})
    assert_raise(ActionController::RoutingError) { @routes.generate({:use_route => 'project', :controller => 'project', :action => 'index'}) }
    assert_equal '/projects/1', @routes.generate({:use_route => 'project', :controller => 'project', :action => 'index', :project_id => '1'})
    assert_equal '/projects/1', @routes.generate({:use_route => 'project', :controller => 'project', :action => 'index'}, {:project_id => '1'})

    assert_equal '/ws/posts/show/1', @routes.generate(:controller => 'posts', :action => 'show', :id => '1', :ws => true)
    assert_equal '/ws/posts', @routes.generate(:controller => 'posts', :action => 'index', :ws => true)

    assert_equal '/account', @routes.generate(:controller => 'account', :action => 'subscription')
    assert_equal '/account/billing', @routes.generate(:controller => 'account', :action => 'billing')

    assert_equal '/pages/1/notes/show/1', @routes.generate(:page_id => '1', :controller => 'notes', :action => 'show', :id => '1')
    assert_equal '/pages/1/notes/list', @routes.generate(:page_id => '1', :controller => 'notes', :action => 'list')
    assert_equal '/pages/1/notes', @routes.generate(:page_id => '1', :controller => 'notes', :action => 'index')
    assert_equal '/pages/1/notes', @routes.generate(:page_id => '1', :controller => 'notes')
    assert_equal '/notes', @routes.generate(:page_id => nil, :controller => 'notes')
    assert_equal '/notes', @routes.generate(:controller => 'notes')
    assert_equal '/notes/print', @routes.generate(:controller => 'notes', :action => 'print')
    assert_equal '/notes/print', @routes.generate({}, {:controller => 'notes', :action => 'print'})
    assert_equal '/notes/index/1', @routes.generate({}, {:controller => 'notes', :id => '1'})
    assert_equal '/notes/show/1', @routes.generate({}, {:controller => 'notes', :action => 'show', :id => '1'})
    assert_equal '/posts', @routes.generate({:controller => 'posts'}, {:controller => 'notes', :action => 'show', :id => '1'})
    assert_equal '/notes/list', @routes.generate({:action => 'list'}, {:controller => 'notes', :action => 'show', :id => '1'})

    assert_equal '/posts/ping', @routes.generate(:controller => 'posts', :action => 'ping')
    assert_equal '/posts/show/1', @routes.generate(:controller => 'posts', :action => 'show', :id => '1')
    assert_equal '/posts', @routes.generate(:controller => 'posts')
    assert_equal '/posts', @routes.generate(:controller => 'posts', :action => 'index')
    assert_equal '/posts', @routes.generate({:controller => 'posts'}, {:controller => 'posts', :action => 'index'})
    assert_equal '/posts/create', @routes.generate({:action => 'create'}, {:controller => 'posts'})
    assert_equal '/posts?foo=bar', @routes.generate(:controller => 'posts', :foo => 'bar')
    assert_equal '/posts?foo%5B%5D=bar&foo%5B%5D=baz', @routes.generate(:controller => 'posts', :foo => ['bar', 'baz'])
    assert_equal '/posts?page=2', @routes.generate(:controller => 'posts', :page => 2)
    assert_equal '/posts?q%5Bfoo%5D%5Ba%5D=b', @routes.generate(:controller => 'posts', :q => { :foo => { :a => 'b'}})

    assert_equal '/', @routes.generate(:controller => 'news', :action => 'index')
    assert_equal '/', @routes.generate(:controller => 'news', :action => 'index', :format => nil)
    assert_equal '/news.rss', @routes.generate(:controller => 'news', :action => 'index', :format => 'rss')

    # assert_equal "/posts/act#{UriReservedCharacters::ESCAPED}ion", @routes.generate(:controller => 'posts', :action => "act#{UriReservedCharacters::SEGMENT}ion")

    assert_raise(ActionController::RoutingError) { @routes.generate({:action => 'index'}) }
  end

  def test_generate_extras
    assert_equal ['/people', []], @routes.generate_extras(:controller => 'people')
    assert_equal ['/people', [:foo]], @routes.generate_extras(:controller => 'people', :foo => 'bar')
    assert_equal ['/people', []], @routes.generate_extras(:controller => 'people', :action => 'index')
    assert_equal ['/people', [:foo]], @routes.generate_extras(:controller => 'people', :action => 'index', :foo => 'bar')
    assert_equal ['/people/new', []], @routes.generate_extras(:controller => 'people', :action => 'new')
    assert_equal ['/people/new', [:foo]], @routes.generate_extras(:controller => 'people', :action => 'new', :foo => 'bar')
    assert_equal ['/people/1', []], @routes.generate_extras(:controller => 'people', :action => 'show', :id => '1')
    assert_equal ['/people/1', [:bar, :foo]], sort_extras!(@routes.generate_extras(:controller => 'people', :action => 'show', :id => '1', :foo => '2', :bar => '3'))
    assert_equal ['/people', [:person]], @routes.generate_extras(:controller => 'people', :action => 'create', :person => { :first_name => 'Josh', :last_name => 'Peek' })
    assert_equal ['/people', [:people]], @routes.generate_extras(:controller => 'people', :action => 'create', :people => ['Josh', 'Dave'])

    assert_equal ['/posts/show/1', []], @routes.generate_extras(:controller => 'posts', :action => 'show', :id => '1')
    assert_equal ['/posts/show/1', [:bar, :foo]], sort_extras!(@routes.generate_extras(:controller => 'posts', :action => 'show', :id => '1', :foo => '2', :bar => '3'))
    assert_equal ['/posts', []], @routes.generate_extras(:controller => 'posts', :action => 'index')
    assert_equal ['/posts', [:foo]], @routes.generate_extras(:controller => 'posts', :action => 'index', :foo => 'bar')
  end

  def test_extras
    params = {:controller => 'people'}
    assert_equal [], @routes.extra_keys(params)
    assert_equal({:controller => 'people'}, params)

    params = {:controller => 'people', :foo => 'bar'}
    assert_equal [:foo], @routes.extra_keys(params)
    assert_equal({:controller => 'people', :foo => 'bar'}, params)

    params = {:controller => 'people', :action => 'create', :person => { :name => 'Josh'}}
    assert_equal [:person], @routes.extra_keys(params)
    assert_equal({:controller => 'people', :action => 'create', :person => { :name => 'Josh'}}, params)
  end

  private
    def sort_extras!(extras)
      if extras.length == 2
        extras[1].sort! { |a, b| a.to_s <=> b.to_s }
      end
      extras
    end

    def assert_raise(e)
      result = yield
      flunk "Did not raise #{e}, but returned #{result.inspect}"
    rescue e
      assert true
    end
end

class TestActionControllerRouteSet < Test::Unit::TestCase
  include RailsRouteSetTests

  def assert_loaded!
    if defined? ActionController::Routing::RouteSet::Dispatcher
      flunk "ActionController tests are running on monkey patched RouteSet"
    end
  end
end

class TestRackMountRouteSet < Test::Unit::TestCase
  include RailsRouteSetTests

  def setup
    require File.join(File.dirname(__FILE__), '..', 'rails', 'init')
    super
  end

  def assert_loaded!
    unless defined? ActionController::Routing::RouteSet::Dispatcher
      flunk "Rack::Mount tests are running without the proper monkey patch"
    end
  end
end