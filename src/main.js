console.log("ha");

$(function() {
  var canvas = $("#canvas")[0];
  var context = canvas.getContext('2d');

  function makegrid(x, y) {
    var grid = [];

    for (var i = 0; i < x; i++) {
      grid[i] = [];

      for (var j = 0; j < y; j++) {
        grid[i][j] = i + j;
      }
    }

    return grid;
  }

  function normalize(grid) {
    var highest = _.chain(grid).flatten().max().value();

    return _.map(grid, function(row) {
      return _.map(row, function(elem) { return elem / highest; });
    });
  }

  function intensityToGrayscale(intensity) {
    var scaledValue = Math.floor(intensity * 255);

    return "rgb(" + scaledValue + ", " + scaledValue + ", " + scaledValue + ")";
  }

  function displaygrid(grid) {
    var tilesize = 20;

    _.each(grid, function(row, i) {
      _.each(row, function(cell, j) {
        context.fillStyle = intensityToGrayscale(cell);
        context.fillRect(i * tilesize, j * tilesize, tilesize, tilesize);
      });
    });

    return grid;
  }

  function main() {
    var grid = displaygrid(normalize(makegrid(10, 10)));
  }

  main();
});