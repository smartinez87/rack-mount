class Tracer
  def initialize(app, name)
    @app  = app
    @name = name
  end

  def call(env)
    env["tracer"] = @name
    @app.call(env)
  end
end