var fs  = require('fs')
  , util = require('util')

function Configurator (file) {
  var config = {},
      oldConfig = {};

  this.updateConfig = function () {
    console.log('reading config file: ' + file);

    fs.readFile(file, function (err, data) {
      if (err) { throw err; }
      old_config = this.config;

      this.config = JSON.parse(data);
      this.emit('configChanged', this.config);
    }.bind(this));
  }.bind(this);

  this.updateConfig();

  fs.watchFile(file, function (curr, prev) {
    if (curr.ino != prev.ino) { this.updateConfig(); }
  }.bind(this));
};

util.inherits(Configurator, process.EventEmitter);

exports.Configurator = Configurator;

exports.configFile = function(file, callback) {
  var config = new Configurator(file);
  config.on('configChanged', function() {
    callback(config.config, config.oldConfig);
  });
};
