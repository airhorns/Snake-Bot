require 'thread'
require 'optparse'
Thread.abort_on_exception = true
include Java
import java.awt.Color
import java.awt.Point
import java.awt.image.BufferedImage
import java.awt.Robot
import java.awt.Toolkit
import java.awt.Rectangle
import java.awt.Dimension
import javax.imageio.ImageIO
import java.awt.Graphics2D
import java.awt.event.InputEvent
import java.awt.event.KeyEvent
require './color.rb'
require './direction.rb'

module Snake
  BLACK = Color.new(0,0,0)
  WHITE = Color.new(255, 255, 255) 
  PAGE_BACKGROUND_COLOR = WHITE # The background of the page where the game is
  GAME_BORDER_COLOR = BLACK # The 1px border around the game space
  GAME_BACKGROUND_COLOR = Color.new(238,238,238) # The bg of the game space
  SNAKE_COLOR = Color.new(85,85,136) # The bg of the game space
  SNAKE_COLOR_RGB = SNAKE_COLOR.getRGB
  SNAKE_COLOR_HSB = SNAKE_COLOR.hsb_array
  FOOD_COLOR = Color.new(255,13,0) # The bg of the game space
  FOOD_COLOR_RGB = FOOD_COLOR.getRGB
  FOOD_COLOR_HSB = FOOD_COLOR.hsb_array
  SQUARE_LENGTH = 8
  FOOD_ADDS_SQUARES = 5
  GAME_HEIGHT = 255
  GAME_WIDTH = 510
  GAME_GRID_HEIGHT = 32
  GAME_GRID_WIDTH = 64
  MAX_CHECKS = 200
  PATTERN_SEARCH = Rectangle.new(20, 400, 100, 100)
  ONE_SQUARE_TIME = 0.0621
  DELAYED_WATCH_MODE = false
  MAKE_SHORT_GOS_TIMED = false
  TIME_GOS_UNDER_LENGTH = 4

  require './point.rb' 
  Game = GameSingleton.instance

  require './watcher.rb'
  require './interactor.rb'
  #require './threaded_watcher.rb'
  require './strategies/strategy.rb'
  require './strategies/dumb.rb'
  require './strategies/columns.rb'
  require './strategies/test.rb'
  require './player.rb'
end
