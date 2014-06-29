// Generated by CoffeeScript 1.7.1
(function() {
  $(function() {
    var $canvas, $renderTemplate, $templ, SMOOTHNESS, TILES, TILESIZE, context, depthToLandType, displaygrid, getBoundary, grid, infobar, intensityToColor, killAllChildren, main, makegrid, mouseX, mouseY, mousedown, mousemove, normalize, render, renderGrid, renderInfobar, renderSelection, rgb, snapToGrid, snapToIndex, templ, terrainize, upperRangeBoundaries;
    TILESIZE = 20;
    TILES = 50;
    SMOOTHNESS = 10;
    $canvas = $("#canvas");
    context = $canvas[0].getContext("2d");
    upperRangeBoundaries = [
      {
        name: "water",
        value: 0.3
      }, {
        name: "land",
        value: 0.7
      }, {
        name: "mountain",
        value: 0.9
      }, {
        name: "snow",
        value: 1.0
      }
    ];
    infobar = {
      selectionName: "something",
      stat: [
        {
          name: "type",
          value: "land"
        }, {
          name: "height",
          value: "10"
        }
      ]
    };
    grid = void 0;
    mouseX = 0;
    mouseY = 0;
    makegrid = function(x, y) {
      var i, j, _i, _results;
      _results = [];
      for (i = _i = 0; 0 <= x ? _i < x : _i > x; i = 0 <= x ? ++_i : --_i) {
        _results.push((function() {
          var _j, _results1;
          _results1 = [];
          for (j = _j = 0; 0 <= y ? _j < y : _j > y; j = 0 <= y ? ++_j : --_j) {
            _results1.push(0);
          }
          return _results1;
        })());
      }
      return _results;
    };
    terrainize = function(grid) {
      var deltas, i, iteration, j, k, neighborScores, neighbors, new_i, new_j, _i, _j, _k, _l, _ref, _ref1, _ref2;
      for (iteration = _i = 0; 0 <= SMOOTHNESS ? _i < SMOOTHNESS : _i > SMOOTHNESS; iteration = 0 <= SMOOTHNESS ? ++_i : --_i) {
        deltas = [
          {
            x: 0,
            y: 1
          }, {
            x: 0,
            y: -1
          }, {
            x: 1,
            y: 0
          }, {
            x: -1,
            y: 0
          }
        ];
        for (i = _j = 0, _ref = grid.length; 0 <= _ref ? _j < _ref : _j > _ref; i = 0 <= _ref ? ++_j : --_j) {
          for (j = _k = 0, _ref1 = grid[0].length; 0 <= _ref1 ? _k < _ref1 : _k > _ref1; j = 0 <= _ref1 ? ++_k : --_k) {
            neighborScores = 0;
            neighbors = 0;
            for (k = _l = 0, _ref2 = deltas.length; 0 <= _ref2 ? _l < _ref2 : _l > _ref2; k = 0 <= _ref2 ? ++_l : --_l) {
              new_i = i + deltas[k].x;
              new_j = j + deltas[k].y;
              if (new_i < 0 || new_i >= grid.length || new_j < 0 || new_j >= grid[0].length) {
                continue;
              }
              neighborScores += grid[new_i][new_j];
              neighbors++;
            }
            grid[i][j] = (neighborScores / neighbors) + (6 * Math.random() - 3) / (iteration + 1);
          }
        }
      }
      return grid;
    };
    normalize = function(grid) {
      var highest, lowest;
      highest = _.chain(grid).flatten().max().value();
      lowest = _.chain(grid).flatten().min().value();
      return _.map(grid, function(row) {
        return _.map(row, function(elem) {
          return (elem - lowest) / (highest - lowest);
        });
      });
    };
    rgb = function(r, g, b) {
      return "rgb(" + (Math.floor(r)) + ", " + (Math.floor(g)) + ", " + (Math.floor(b)) + ")";
    };
    getBoundary = function(name) {
      var i, _i, _ref;
      for (i = _i = 0, _ref = upperRangeBoundaries.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (upperRangeBoundaries[i].name === name) {
          return upperRangeBoundaries[i].value;
        }
      }
    };
    depthToLandType = function(depth) {
      var i, _i, _ref;
      for (i = _i = 0, _ref = upperRangeBoundaries.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (depth <= upperRangeBoundaries[i].value) {
          return upperRangeBoundaries[i].name;
        }
      }
      return upperRangeBoundaries[upperRangeBoundaries.length - 1].name;
    };
    intensityToColor = function(intensity) {
      var blue, green, normalizedIntensity, red;
      red = void 0;
      blue = void 0;
      green = void 0;
      normalizedIntensity = void 0;
      if (intensity < getBoundary("water")) {
        normalizedIntensity = intensity / 0.3;
        blue = normalizedIntensity * 100 + 155;
        green = normalizedIntensity * 80;
        red = 0;
      } else if (intensity < getBoundary("land")) {
        normalizedIntensity = (intensity - 0.3) / 0.4;
        green = (1 - normalizedIntensity) * 100 + 100;
        red = 0;
        blue = 0;
      } else if (intensity < getBoundary("mountain")) {
        normalizedIntensity = (intensity - 0.7) / 0.20;
        red = 100 - intensity * 60;
        blue = 0;
        green = 50;
      } else {
        red = blue = green = Math.floor(intensity * 255);
      }
      return rgb(red, green, blue);
    };
    $renderTemplate = function(template, data) {
      var $childTemplateLists, $childTemplates, $el, classname, i, key, templateList, thisLevelData;
      thisLevelData = {};
      $childTemplates = {};
      $childTemplateLists = {};
      for (key in data) {
        if (_.isArray(data[key])) {
          templateList = [];
          i = 0;
          while (i < data[key].length) {
            templateList.push($renderTemplate(template + "-" + key, data[key][i]));
            i++;
          }
          $childTemplateLists[key] = templateList;
        } else if (_.isObject(data[key])) {
          $childTemplates[key] = $renderTemplate(template + "-" + key, data[key]);
        } else {
          thisLevelData[key] = data[key];
        }
      }
      $el = $templ(template + "-template", thisLevelData);
      classname = void 0;
      for (classname in $childTemplates) {
        $el.find("." + classname).append($childTemplates[classname]);
      }
      for (classname in $childTemplateLists) {
        $el.find("." + classname).append($childTemplateLists[classname]);
      }
      return $el;
    };
    killAllChildren = function($el) {
      var i;
      i = 0;
      while (i < $el.children().length) {
        $el.children().eq(i).remove();
        i++;
      }
    };
    templ = function(name, data) {
      return _.template(_.unescape($(name).html()))(data);
    };
    $templ = function(name, data) {
      return $("<div/>").html(templ(name, data));
    };
    renderInfobar = function() {
      killAllChildren($(".infobar"));
      $(".infobar").append($renderTemplate(".infobar", infobar));
    };
    displaygrid = function(grid) {
      _.each(grid, function(row, i) {
        _.each(row, function(cell, j) {
          context.fillStyle = intensityToColor(cell);
          context.fillRect(i * TILESIZE, j * TILESIZE, TILESIZE, TILESIZE);
        });
      });
      return grid;
    };
    snapToGrid = function(value) {
      return Math.floor(value / TILESIZE) * TILESIZE;
    };
    snapToIndex = function(value) {
      return Math.floor(value / TILESIZE);
    };
    mousemove = function(e) {
      mouseX = e.pageX - $canvas.offset().left;
      mouseY = e.pageY - $canvas.offset().top;
    };
    mousedown = function(e) {
      var gridvalue;
      gridvalue = grid[snapToIndex(mouseX)][snapToIndex(mouseY)];
      infobar.selectionName = depthToLandType(gridvalue);
      infobar.stat = [
        {
          name: "height",
          value: gridvalue * 100
        }
      ];
      renderInfobar();
    };
    renderGrid = function(grid) {
      displaygrid(grid);
    };
    renderSelection = function() {
      context.fillStyle = rgb(0, 0, 0);
      context.strokeRect(snapToGrid(mouseX), snapToGrid(mouseY), TILESIZE, TILESIZE);
    };
    render = function() {
      renderGrid(grid);
      renderSelection();
      requestAnimationFrame(render);
    };
    main = function() {
      grid = normalize(terrainize(makegrid(TILES, TILES)));
      renderGrid(grid);
      $canvas.on("mousemove", mousemove);
      $canvas.on("mousedown", mousedown);
      requestAnimationFrame(render);
    };
    main();
    renderInfobar();
  });

}).call(this);

//# sourceMappingURL=main.map
