var url = require('url');
var log = require('./log');
var path = require('path');
var download = require('./download').download;
var parseContentDisposition = require('content-disposition').parse;

// sorted from worst to best
var YTDL_AUDIO_ENCODINGS = [];

module.exports = [
  {
    name: "YouTube Download",
    fn: ytdlImportUrl,
  },
  {
    name: "Raw Download",
    fn: downloadRawImportUrl,
  },
];

var spawn = require('child_process').spawn;

function ytdlImportUrl(urlString, cb) {
  var parsedUrl = url.parse(urlString);

  var isYouTube = (parsedUrl.pathname === '/watch' &&
    (parsedUrl.hostname === 'youtube.com' ||
      parsedUrl.hostname === 'www.youtube.com' ||
      parsedUrl.hostname === 'm.youtube.com')) ||
    parsedUrl.hostname === 'youtu.be' ||
    parsedUrl.hostname === 'www.youtu.be';

  if (!isYouTube) {
    cb();
    return;
  }

  // Get info first
  var args = ['-j', urlString];
  var infoProcess = spawn('yt-dlp', args);
  var stdout = '';
  infoProcess.stdout.on('data', function (data) {
    stdout += data;
  });
  infoProcess.on('close', function (code) {
    if (code !== 0) {
      return cb(new Error("yt-dlp info failed with code " + code));
    }
    var info;
    try {
      info = JSON.parse(stdout);
    } catch (e) {
      return cb(e);
    }

    var filenameHintWithoutPath = info.title + '.' + (info.ext || 'mp3');

    // Start download stream
    var dlArgs = ['-o', '-', '-f', 'ba/b', urlString];
    var dlProcess = spawn('yt-dlp', dlArgs);

    cb(null, dlProcess.stdout, filenameHintWithoutPath, null);
  });
}

function downloadRawImportUrl(urlString, cb) {
  var parsedUrl = url.parse(urlString);
  var remoteFilename = path.basename(parsedUrl.pathname);
  var decodedFilename;
  try {
    decodedFilename = decodeURI(remoteFilename);
  } catch (err) {
    decodedFilename = remoteFilename;
  }
  download(urlString, function (err, resp) {
    if (err) return cb(err);
    var contentDisposition = resp.headers['content-disposition'];
    if (contentDisposition) {
      var filename;
      try {
        filename = parseContentDisposition(contentDisposition).parameters.filename;
      } catch (err) {
        // do nothing
      }
      if (filename) {
        decodedFilename = filename;
      }
    }
    var contentLength = parseInt(resp.headers['content-length'], 10);
    cb(null, resp, decodedFilename, contentLength);
  });
}
