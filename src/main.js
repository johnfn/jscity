$(function() {
  var TILESIZE = 20;
  var TILES = 50;
  var SMOOTHNESS = 10;

  var $canvas = $("#canvas");
  var context = $canvas[0].getContext('2d');

  function makegrid(x, y) {
    var grid = [];

    for (var i = 0; i < x; i++) {
      grid[i] = [];

      for (var j = 0; j < y; j++) {
        grid[i][j] = 0;
      }
    }

    return grid;
  }

  function terrainize(grid) {
    // more iterations == more smoothness as we repeatedly make cells closer in value to their neighbors.

    for (var iterations = 0; iterations < SMOOTHNESS; iterations++) {
      var deltas = [{x:0, y:1}, {x:0, y:-1}, {x:1, y:0}, {x:-1, y:0}];

      for (var i = 1; i < grid.length; i++) {
        for (var j = 1; j < grid[0].length; j++) {
          var neighborScores = 0;
          var neighbors = 0;

          for (var k = 0; k < deltas.length; k++) {
            var new_i = i + deltas[k].x;
            var new_j = j + deltas[k].y;

            if (new_i < 0 || new_i >= grid.length || new_j < 0 || new_j >= grid[0].length) continue;

            neighborScores += grid[new_i][new_j];
            neighbors++;
          }

          grid[i][j] = neighborScores / neighbors + (6 * Math.random() - 3) / (iterations + 1);
        }
      }
    }

    return grid;
  }

  function normalize(grid) {
    var highest = _.chain(grid).flatten().max().value();
    var lowest  = _.chain(grid).flatten().min().value();

    return _.map(grid, function(row) {
      return _.map(row, function(elem) { return (elem - lowest) / (highest - lowest); });
    });
  }

  function rgb(r, g, b) {
    r = Math.floor(r);
    g = Math.floor(g);
    b = Math.floor(b);

    return "rgb(" + r + ", " + g + ", " + b + ")";
  }

  function intensityToColor(intensity) {
    var red, blue, green;
    var normalizedIntensity;

    if (intensity < 0.3) {
      // deepest areas are oceans, so calculate a water color via handwave.

      normalizedIntensity = intensity / 0.3;

      blue = normalizedIntensity * 100 + 155;
      green = normalizedIntensity * 80;
      red = 0;
    } else if (intensity < 0.7) {
      // middle areas are land, so reapply handwave technique

      normalizedIntensity = (intensity - 0.3) / 0.4;

      green = (1 - normalizedIntensity) * 100 + 100;
      red = 0;
      blue = 0;

    } else if (intensity < 0.90) {
      // mountains

      normalizedIntensity = (intensity - 0.7) / 0.20;

      red = 100 - intensity * 60;
      blue = 0;
      green = 50;
    } else {
      // snowpeaks!

      red = blue = green = Math.floor(intensity * 255);
    }

    return rgb(red, green, blue);
  }

  // INFOBAR

  var infobar = {
    selectionName: "something",
    stat: {
      height: "10",
      type: "land"
    }
  };

  function $renderTemplate(template, data) {
    var thisLevelData = {};
    var $childTemplates = {};

    for (var key in data) {
      if (typeof data[key] === "object") {
        $childTemplates[key] = $renderTemplate(template + "-" + key, data[key]);

        continue;
      }

      thisLevelData[key] = data[key];
    }

    var $el = $templ(template + "-template", thisLevelData);

    for (var classname in $childTemplates) {
      $el.find("." + classname).append($childTemplates[classname]);
    }

    return $el;
  }

  function killAllChildren($el) {
    for (var i = 0; i < $el.children().length; i++) {
      $el.children().eq(i).remove();
    }
  }

  function templ(name, data) {
    return _.template(_.unescape($(name).html()))(data);
  }

  function $templ(name, data) {
    return $("<div/>").html(templ(name, data));
  }

  function renderInfobar() {
    killAllChildren($(".infobar"));

    $(".infobar").append($renderTemplate(".infobar", infobar))
  }

  renderInfobar();

  function displaygrid(grid) {
    _.each(grid, function(row, i) {
      _.each(row, function(cell, j) {
        context.fillStyle = intensityToColor(cell);
        context.fillRect(i * TILESIZE, j * TILESIZE, TILESIZE, TILESIZE);
      });
    });

    return grid;
  }

  var grid;
  var mouseX = 0;
  var mouseY = 0;

  function snapToGrid(value) {
    return Math.floor(value / TILESIZE) * TILESIZE;
  }

  function mousemove(e) {
    mouseX = e.pageX - $canvas.offset().left;
    mouseY = e.pageY - $canvas.offset().top;
  }

  function renderGrid(grid) {
    displaygrid(normalize(grid));
  }

  function renderSelection() {
    context.fillStyle = rgb(0, 0, 0);
    context.strokeRect(snapToGrid(mouseX), snapToGrid(mouseY), TILESIZE, TILESIZE);
  }

  function render() {
    renderGrid(grid);
    renderSelection();

    requestAnimationFrame(render);
  }

  function main() {
    // It annoys me that these are in reverse order.
    grid = terrainize(makegrid(TILES, TILES));

    renderGrid(grid);
    $canvas.on("mousemove", mousemove);

    requestAnimationFrame(render);
  }

  main();

  renderInfobar();
});