$(function() {
  var canvas = $("#canvas")[0];
  var context = canvas.getContext('2d');

  var TILESIZE = 10;
  var TILES = 50;

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
    for (var iterations = 0; iterations < 10; iterations++) {
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

  function intensityToGrayscale(intensity) {
    var scaledValue = Math.floor(intensity * 255);

    return "rgb(" + scaledValue + ", " + scaledValue + ", " + scaledValue + ")";
  }

  function displaygrid(grid) {
    _.each(grid, function(row, i) {
      _.each(row, function(cell, j) {
        context.fillStyle = intensityToGrayscale(cell);
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