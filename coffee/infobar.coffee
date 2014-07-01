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





class Infobar
  constructor: (@grid) ->
    G.mouse.click (mi) => @click(mi)

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
    $(".btn").on "click", (e) =>
      G.buildings.build $.trim($(e.currentTarget).text())

depthToLandType = (depth) ->
  for i in [0...G.upperRangeBoundaries.length] when depth <= G.upperRangeBoundaries[i].value
    return G.upperRangeBoundaries[i].name

  # should never be executed, but just in case.
  # maybe they developed terraforming.
  G.upperRangeBoundaries[G.upperRangeBoundaries.length - 1].name

window.Infobar = Infobar