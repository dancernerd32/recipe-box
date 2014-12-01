require 'sinatra'
require 'pg'
require 'pry'
require 'sinatra/reloader'

def db_connection
  begin
    connection = PG.connect(dbname: 'recipes')

    yield(connection)

  ensure
    connection.close
  end
end

get '/recipes' do


  db_connection do |connection|
    if params[:page]
      @page_number = params[:page].to_i
    else
      @page_number = 1
    end
    @recipes = connection.exec ("SELECT name, id FROM recipes ORDER BY name
    LIMIT 20 OFFSET #{(@page_number-1) * 20}")
    @number_of_pages = connection.exec("SELECT id FROM recipes").to_a.length / 20
  end
  @recipe_list = @recipes.to_a

  erb :'/recipes/index'
end

get '/' do
  redirect '/recipes'
end

get '/recipes/:id' do
  @id = params[:id]
  db_connection do |connection|
    @recipe = connection.exec("SELECT recipes.name AS recipe_name, recipes.description, recipes.instructions, ingredients.name AS
    ingredients
    FROM recipes
    JOIN ingredients ON ingredients.recipe_id = recipes.id
    WHERE recipes.id = $1", [@id])
  end
  @this_recipe = @recipe[0]
  @instructions = @this_recipe['instructions'].split("\n")
  @instruction_title = @instructions[1]
  @description = @this_recipe['description'].split("\n")
  erb :'/recipes/show'
end
