Function::getter = (prop, get) -> Object.defineProperty @prototype, prop, {get, configurable: yes}
Function::setter = (prop, set) -> Object.defineProperty @prototype, prop, {set, configurable: yes}

$ ->
  TILESIZE = 20
  TILES = 50
  SMOOTHNESS = 10

  $canvas = $("#canvas")
  context = $canvas[0].getContext("2d")

  upperRangeBoundaries = [
    {
      name: "water"
      value: 0.3
    }
    {
      name: "land"
      value: 0.7
    }
    {
      name: "mountain"
      value: 0.9
    }
    {
      name: "snow"
      value: 1.0
    }
  ]


  class Infobar
    constructor: (@grid) ->
      G.mouse.onclick (mi) => @click(mi)

      @data =
        selectionName: "something"
        stat: [
          { name: "type", value: "land" }
          { name: "height", value: "10" }
        ]
        buttons: [
          { name: "Power Plant" }
          { name: "Road" }
        ]

    click: (mouseinfo) ->
      value = G.grid.valueAt(mouseinfo.tilex, mouseinfo.tiley)

      @data.selectionName = depthToLandType(value)
      @data.stat = [
        name: "height"
        value: Math.floor(value * 100)
      ]

      @render()

    render: () ->
      killAllChildren $(".infobar")
      $(".infobar").append $renderTemplate(".infobar", @data)


  getBoundary = (name) ->
    for i in [0...upperRangeBoundaries.length] when upperRangeBoundaries[i].name == name
      return upperRangeBoundaries[i].value

  depthToLandType = (depth) ->
    for i in [0...upperRangeBoundaries.length] when depth <= upperRangeBoundaries[i].value
      return upperRangeBoundaries[i].name

    # should never be executed, but just in case.
    # maybe they developed terraforming.
    upperRangeBoundaries[upperRangeBoundaries.length - 1].name

  intensityToColor = (intensity) ->
    red = undefined
    blue = undefined
    green = undefined
    normalizedIntensity = undefined

    # REFACTORING need to move the color calc functions into upperRangeBoundaries fn.
    if intensity < getBoundary("water")

      # deepest areas are oceans, so calculate a water color via handwave.
      normalizedIntensity = intensity / 0.3
      blue = normalizedIntensity * 100 + 155
      green = normalizedIntensity * 80
      red = 0
    else if intensity < getBoundary("land")

      # middle areas are land, so reapply handwave technique
      normalizedIntensity = (intensity - 0.3) / 0.4
      green = (1 - normalizedIntensity) * 100 + 100
      red = 0
      blue = 0
    else if intensity < getBoundary("mountain")

      # mountains
      normalizedIntensity = (intensity - 0.7) / 0.20
      red = 100 - intensity * 60
      blue = 0
      green = 50
    else

      # snowpeaks!
      red = blue = green = Math.floor(intensity * 255)
    G.rgb red, green, blue

  #
  #   * 20-line-long-better-than-backbone templating.
  #   *
  #   * An object is a template.
  #   * A key is a value on that template. If it's an object, it's a subtemplate.
  #   * An array is a list of templates.
  #   *
  #
  $renderTemplate = (template, data) ->
    thisLevelData = {}
    $childTemplates = {}
    $childTemplateLists = {}
    for key of data
      if _.isArray(data[key])
        templateList = []
        i = 0

        while i < data[key].length
          templateList.push $renderTemplate(template + "-" + key, data[key][i])
          i++
        $childTemplateLists[key] = templateList

      # _.isObject([]) == "true" WUT WUT WUT
      else if _.isObject(data[key])
        $childTemplates[key] = $renderTemplate(template + "-" + key, data[key])
      else
        thisLevelData[key] = data[key]
    $el = $templ(template + "-template", thisLevelData)

    for classname of $childTemplates
      $el.find("." + classname).append $childTemplates[classname]

    for classname of $childTemplateLists
      $el.find("." + classname).append $childTemplateLists[classname]

    $el

  killAllChildren = ($el) ->
    $(child).remove() for child in $el.children()

  templ = (name, data) ->
    _.template(_.unescape($(name).html())) data

  $templ = (name, data) ->
    $("<span/>").html templ(name, data)

  snapToGrid = (value) -> Math.floor(value / TILESIZE) * TILESIZE

  class Game
    constructor: () ->
      console.log("bleh")

  class MouseInfo
    constructor: (@x, @y, @tilex, @tiley) ->

  class Mouse
    constructor: ($canvas) ->
      $canvas.on "mousemove", (e) => @mousemove(e)
      $canvas.on "mousedown", (e) => @mousedown(e)

      @x = @y = 0
      @callbacks = []

    onclick: (cb) ->
      @callbacks.push(cb)

    mousemove: (e) ->
      @x = e.pageX - $canvas.offset().left
      @y = e.pageY - $canvas.offset().top

    snapToIndex: (value) -> Math.floor value / TILESIZE

    mousedown: (e) ->
      mi = new MouseInfo(@x, @y, @snapToIndex(@x), @snapToIndex(@y))
      callback(mi) for callback in @callbacks

  class Entity
    constructor: (@x, @y) ->
      @children = []

    add: (child) -> @children.push(child); @

    addTo: (entity) -> entity.children.push(@); @

    render: (context) -> console.log("reimplement!")

    _render: (context) ->
      context.translate(@x, @y)

      @render(context)
      child.render(context) for child in @children

      context.translate(-@x, -@y)

  class Grid extends Entity
    constructor: (w, h) ->
      @grid = (0 for i in [0...w] for j in [0...h])
      @terrainize()
      @normalize()

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
      _.each @grid, (row, i) ->
        _.each row, (cell, j) ->
          context.fillStyle = intensityToColor(cell)
          context.fillRect i * TILESIZE, j * TILESIZE, TILESIZE, TILESIZE

  renderSelection = ->
    context.fillStyle = G.rgb(0, 0, 0)
    context.strokeRect snapToGrid(G.mouse.x), snapToGrid(G.mouse.y), TILESIZE, TILESIZE

  renderLoop = ->
    G.stage._render(context)

    renderSelection()
    requestAnimationFrame renderLoop

  # globals
  G = {}
  G.mouse   = new Mouse($canvas)
  G.stage   = new Entity()
  G.grid    = new Grid(TILES, TILES).addTo(G.stage)
  G.infobar = new Infobar(G.grid)
  G.rgb     = (r, g, b) -> "rgb(#{Math.floor(r)}, #{Math.floor(g)}, #{Math.floor(b)})"

  main = ->
    # It annoys me that these are in reverse order.
    G.infobar.render()

    requestAnimationFrame renderLoop

  main()
