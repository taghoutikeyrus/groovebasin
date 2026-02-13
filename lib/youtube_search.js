var execFile = require('child_process').execFile;

module.exports = youtubeSearch;

function youtubeSearch(name, apiKey, cb) {
  // We use yt-dlp for searching to avoid needing an API key
  var args = [
    '--get-id',
    '--default-search', 'ytsearch1',
    name
  ];
  execFile('yt-dlp', args, function (err, stdout, stderr) {
    if (err) {
      return cb(err);
    }
    var videoId = stdout.trim();
    if (!videoId) {
      return cb(new Error("no results found"));
    }
    var fullUrl = "https://youtube.com/watch?v=" + videoId;
    cb(null, fullUrl);
  });
}
