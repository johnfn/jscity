# bubble-down event system


Function::getter = (prop, get) -> Object.defineProperty @prototype, prop, {get, configurable: yes}
Function::setter = (prop, set) -> Object.defineProperty @prototype, prop, {set, configurable: yes}

$ ->
  TILESIZE = 20
  TILES = 50
  SMOOTHNESS = 10

  $canvas = $("#canvas")
  context = $canvas[0].getContext("2d")

  class Game
    constructor: () ->
      console.log("bleh")

  class MouseInfo
    constructor: (@x, @y, @tilex, @tiley) ->

  class Mouse
    constructor: ($canvas) ->
      $canvas.on "mousemove", (e) => @_mousemove(e)
      $canvas.on "mousedown", (e) => @_mousedown(e)

      @x = @y = 0
      @callbacks = {'click': [], 'mousemove': []}

    click: (cb) -> @callbacks['click'].push(cb)

    mousemove: (cb) -> @callbacks['mousemove'].push(cb)

    mi: () -> new MouseInfo(@x, @y, @snapToIndex(@x), @snapToIndex(@y))

    _mousemove: (e) ->
      @x = e.pageX - $canvas.offset().left
      @y = e.pageY - $canvas.offset().top

      callback(@mi()) for callback in @callbacks['mousemove']

    snapToIndex: (value) -> Math.floor value / TILESIZE

    _mousedown: (e) -> callback(@mi()) for callback in @callbacks['click']

  class Entity
    constructor: (@x, @y) ->
      @children = []

      # width calculated from graphical components on just this entity
      @_basewidth = @_baseheight = 0

      # width/height of this entity from everything incl nested children
      @_width = @_height = 0

    add: (child) -> @children.push(child); @

    addTo: (entity) -> entity.children.push(@); @

    render: (context) ->

    drawRect: (x, y, w, h, color) ->
      context.fillStyle = color
      context.fillRect x, y, w, h

      @_basewidth  = Math.max(@_basewidth, x + w)
      @_baseheight = Math.max(@_baseheight, y + h)

    strokeRect: (x, y, w, h, color) ->
      context.fillStyle = color
      context.strokeRect x, y, w, h

      @_basewidth  = Math.max(@_basewidth, x + w)
      @_baseheight = Math.max(@_baseheight, y + h)

    snap: (value) -> Math.floor(value / TILESIZE) * TILESIZE

    width: ()  ->
      @_width

    height: () ->
      @_height

    moveTo: (x, y) ->
      @x = x
      @y = y
      @

    snapToGrid: () ->
      @x = @snap(@x)
      @y = @snap(@y)
      @

    _preupdate: () ->
      @_width = Math.max @_width, @_basewidth
      @_height = Math.max @_height, @_baseheight

      child._preupdate() for child in @children

      @_width  = Math.max(@_width, Math.max _.pluck(@children, "_width")...)
      @_height = Math.max(@_height, Math.max _.pluck(@children, "_height")...)

    _render: (context) ->
      # we are about to recalculate the width in @render, so 0 them out.
      @_width = 0
      @_height = 0

      @render(context)

      context.translate(@x, @y)
      child._render(context) for child in @children
      context.translate(-@x, -@y)

  class Selection extends Entity
    constructor: () -> super(0, 0)

    render: (context) ->
      @strokeRect @x, @y, TILESIZE, TILESIZE, G.rgb(0, 0, 0)

  class Buildings extends Entity
    constructor: () -> super()

    build: (type) ->
      loc = G.stage.staticSelection

      building = switch type
        when "Power Plant" then new PowerPlant(loc.x, loc.y)

      this.add(building)

  class Building extends Entity
    constructor: (@x, @y, @name) -> super(@x, @y)

  class PowerPlant extends Building
    constructor: (@x, @y) ->
      super(@x, @y, "Power Plant")

    render: (context) ->
      @drawRect @x, @y, TILESIZE, TILESIZE, G.rgb(255, 255, 0)

    click: () ->
      console.log("click!")

  class Stage extends Entity
    constructor: () ->
      super(0, 0)

    addSelectionIcons: () ->
      @followSelection = new Selection().addTo(@)
      @staticSelection = new Selection().addTo(@)

      G.mouse.click (mi) => @moveStaticSelection(mi)
      G.mouse.mousemove (mi) => @moveFollowSelection(mi)

    moveStaticSelection: (mi) ->
      @staticSelection.moveTo(mi.x, mi.y).snapToGrid()

    moveFollowSelection: (mi) ->
      @followSelection.moveTo(mi.x, mi.y).snapToGrid()


  class Grid extends Entity
    constructor: (w, h) ->
      super(0, 0)

      @grid = (0 for i in [0...w] for j in [0...h])

      @terrainize()
      @normalize()

    getBoundary: (name) ->
      for i in [0...G.upperRangeBoundaries.length] when G.upperRangeBoundaries[i].name == name
        return G.upperRangeBoundaries[i].value

    intensityToColor: (intensity) ->
      red = undefined
      blue = undefined
      green = undefined
      normalizedIntensity = undefined

      # REFACTORING need to move the color calc functions into upperRangeBoundaries fn.
      if intensity < @getBoundary("water")

        # deepest areas are oceans, so calculate a water color via handwave.
        normalizedIntensity = intensity / 0.3
        blue = normalizedIntensity * 100 + 155
        green = normalizedIntensity * 80
        red = 0
      else if intensity < @getBoundary("land")

        # middle areas are land, so reapply handwave technique
        normalizedIntensity = (intensity - 0.3) / 0.4
        green = (1 - normalizedIntensity) * 100 + 100
        red = 0
        blue = 0
      else if intensity < @getBoundary("mountain")

        # mountains
        normalizedIntensity = (intensity - 0.7) / 0.20
        red = 100 - intensity * 60
        blue = 0
        green = 50
      else

        # snowpeaks!
        red = blue = green = Math.floor(intensity * 255)
      G.rgb red, green, blue

    terrainize: () ->
      # more iterations == more smoothness as we repeatedly make cells closer in value to their neighbors.
      deltas = [{ x: 0, y: 1}, {x: 0, y: -1 },{ x: 1, y: 0 },{ x: -1, y: 0 }]

      for iteration in [0...SMOOTHNESS]
        for i in [0...@grid.length]
          for j in [0...@grid[0].length]
            neighborScores = 0
            neighbors = 0

            for k in [0...deltas.length]
              new_i = i + deltas[k].x
              new_j = j + deltas[k].y
              continue if new_i < 0 or new_i >= @grid.length or new_j < 0 or new_j >= @grid[0].length
              neighborScores += @grid[new_i][new_j]
              neighbors++

            @grid[i][j] = (neighborScores / neighbors) + (6 * Math.random() - 3) / (iteration + 1)
      @grid

    valueAt: (x,y) -> @grid[x][y]

    normalize: () ->
      highest = Math.max _.flatten(@grid)...
      lowest = Math.min _.flatten(@grid)...

      @grid = ((elem - lowest) / (highest - lowest) for elem in row for row in @grid)

    render: (context) ->
      for i in [0...@grid.length]
        for j in [0...@grid[i].length]
          @drawRect i * TILESIZE, j * TILESIZE, TILESIZE, TILESIZE, @intensityToColor(@valueAt(i, j))

  renderLoop = ->
    G.stage._preupdate()
    G.stage._render(context)

    requestAnimationFrame renderLoop

  # globals
  window.G = G = {}
  G.upperRangeBoundaries = [
    { name: "water", value: 0.3 },
    { name: "land", value: 0.7 },
    { name: "mountain", value: 0.9 },
    { name: "snow", value: 1.0 }
  ]
  G.mouse     = new Mouse($canvas)
  G.grid      = new Grid(TILES, TILES)
  G.stage     = new Stage().add(G.grid)
  G.buildings = new Buildings().addTo(G.stage)
  G.infobar   = new Infobar(G.grid)
  G.rgb       = (r, g, b) -> "rgb(#{Math.floor(r)}, #{Math.floor(g)}, #{Math.floor(b)})"
  G.selection = undefined

  G.stage.addSelectionIcons()

  main = ->
    # It annoys me that these are in reverse order.
    G.infobar.render()

    requestAnimationFrame renderLoop

  main()