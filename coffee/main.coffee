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
  infobar =
    selectionName: "something"
    stat: [
      {
        name: "type"
        value: "land"
      }
      {
        name: "height"
        value: "10"
      }
    ]

  grid = undefined
  mouseX = 0
  mouseY = 0



  makegrid = (x, y) ->
    for i in [0...x]
      for j in [0...y]
        0

  terrainize = (grid) ->
    # more iterations == more smoothness as we repeatedly make cells closer in value to their neighbors.
    for iteration in [0...SMOOTHNESS]
      deltas = [{ x: 0, y: 1}, {x: 0, y: -1 },{ x: 1, y: 0 },{ x: -1, y: 0 }]
      for i in [0...grid.length]
        for j in [0...grid[0].length]
          neighborScores = 0
          neighbors = 0

          for k in [0...deltas.length]
            new_i = i + deltas[k].x
            new_j = j + deltas[k].y
            continue  if new_i < 0 or new_i >= grid.length or new_j < 0 or new_j >= grid[0].length
            neighborScores += grid[new_i][new_j]
            neighbors++

          grid[i][j] = (neighborScores / neighbors) + (6 * Math.random() - 3) / (iteration + 1)
    grid


  normalize = (grid) ->
    highest = _.chain(grid).flatten().max().value()
    lowest = _.chain(grid).flatten().min().value()

    _.map grid, (row) ->
      _.map row, (elem) -> (elem - lowest) / (highest - lowest)

  rgb = (r, g, b) ->
    "rgb(#{Math.floor(r)}, #{Math.floor(g)}, #{Math.floor(b)})"

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
    rgb red, green, blue

  # INFOBAR

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
    classname = undefined
    for classname of $childTemplates
      $el.find("." + classname).append $childTemplates[classname]
    for classname of $childTemplateLists
      $el.find("." + classname).append $childTemplateLists[classname]
    $el
  killAllChildren = ($el) ->
    i = 0

    while i < $el.children().length
      $el.children().eq(i).remove()
      i++
    return
  templ = (name, data) ->
    _.template(_.unescape($(name).html())) data
  $templ = (name, data) ->
    $("<div/>").html templ(name, data)
  renderInfobar = ->
    killAllChildren $(".infobar")
    $(".infobar").append $renderTemplate(".infobar", infobar)
    return
  displaygrid = (grid) ->
    _.each grid, (row, i) ->
      _.each row, (cell, j) ->
        context.fillStyle = intensityToColor(cell)
        context.fillRect i * TILESIZE, j * TILESIZE, TILESIZE, TILESIZE
        return

      return

    grid
  snapToGrid = (value) ->
    Math.floor(value / TILESIZE) * TILESIZE
  snapToIndex = (value) ->
    Math.floor value / TILESIZE
  mousemove = (e) ->
    mouseX = e.pageX - $canvas.offset().left
    mouseY = e.pageY - $canvas.offset().top
    return
  mousedown = (e) ->
    gridvalue = grid[snapToIndex(mouseX)][snapToIndex(mouseY)]
    infobar.selectionName = depthToLandType(gridvalue)
    infobar.stat = [
      name: "height"
      value: gridvalue * 100
    ]
    renderInfobar()
    return
  renderGrid = (grid) ->
    displaygrid grid
    return
  renderSelection = ->
    context.fillStyle = rgb(0, 0, 0)
    context.strokeRect snapToGrid(mouseX), snapToGrid(mouseY), TILESIZE, TILESIZE
    return
  render = ->
    renderGrid grid
    renderSelection()
    requestAnimationFrame render
    return
  main = ->

    # It annoys me that these are in reverse order.
    grid = normalize(terrainize(makegrid(TILES, TILES)))
    renderGrid grid
    $canvas.on "mousemove", mousemove
    $canvas.on "mousedown", mousedown
    requestAnimationFrame render
    return



  main()
  renderInfobar()
  return