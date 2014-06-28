$(function() {
  var TILESIZE = 10;
  var TILES = 50;
  var SMOOTHNESS = 10;

  var canvas = $("#canvas")[0];
  var context = canvas.getContext('2d');

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
    var scaledValue = Math.floor(intensity * 255);

    // deepest areas are oceans.
    if (intensity < 0.3) {
      var blue = (intensity / 0.3) * 100 + 155;
      var green = (intensity / 0.3) * 80;
      var red = 0;

      return rgb(red, green, blue);
    }

    return "rgb(" + scaledValue + ", " + scaledValue + ", " + scaledValue + ")";
  }

  function displaygrid(grid) {
    _.each(grid, function(row, i) {
      _.each(row, function(cell, j) {
        context.fillStyle = intensityToColor(cell);
        context.fillRect(i * TILESIZE, j * TILESIZE, TILESIZE, TILESIZE);
      });
    });

    return grid;
  }

  function main() {
    // It annoys me that these are in reverse order.
    var grid = _.compose(displaygrid, normalize, terrainize, makegrid)(TILES, TILES);
  }

  main();
});