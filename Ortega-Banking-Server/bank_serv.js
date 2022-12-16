//user_id nick full_name race guild operator_id
//card_id card_type acc_id
//acc_id acc_type user_id

const fs = require('fs')
const http = require('http')
const sqlite3 = require('sqlite3').verbose()

const servPort = '8084'
const db = new sqlite3.Database('civil.db')

function Init() {
  try {
    const creationreqs = fs.readFileSync('oncreate.sql', 'utf8')
      .replace(/\-\-.*(\r\n|$)/g, '')
      .replace(/\r\n\s+\r\n/g, '\r\n\r\n')
      .replace(/\r\n([^\r])/g, '$1')
      .split('\r\n');
    log(creationreqs)
    
    db.serialize( function() {
      for (i of creationreqs) {
        db.run(i)
      }
    })
  } catch(e) {
    warn('db already exists or smth', e)
  }
}

function requestHandler (req, resp) {
  var tbody = '';
  req.on('data', chunk => tbody += chunk.toString())
  
  function respond(nstatus, ntext) {
    try {
      ntext = JSON.stringify(ntext)        
    } catch(e) {}
    try {
      ntext = ntext.replace(/"/g,"'")
      ntext = ntext.replace(/(\r|\n)/g,"")
    } catch(e) {
      error('respond(): something is wrong with ntext!', ntext)
    }
    resp.setHeader('Access-Control-Allow-Origin', '*');
    resp.setHeader('Access-Control-Allow-Headers', 'origin, content-type, accept, cache-control');
    resp.writeHead(200, {
			'Content-Type': 'application/json'
		});
    resp.end(`{"status":"${nstatus}", "text":"${ntext}"}`)
  }
  
  if(req.method == 'OPTIONS') {
    respond(200, 'crossdomen')
    return
  }
  
	log(`incoming request: ${req.url}\r\n${new Date().toJSON()}`);

  req.on('end', _ => {
    POSTCallback(tbody)
    .then( ([nstatus, ntext]) => respond(nstatus, ntext) )
    .catch(e => warn(e.message))
  });
}

async function POSTCallback(nbody) {
  
  return [200, 0]
}

const server = http.createServer(requestHandler)
// server.listen(servPort, (err) => {
  // if (err)
    // return warn('something bad happened:', err);
  // log(`server is listening on localhost:${servPort}`)
// })
Init()

/////////MISC
function log(...e) {
  console.log(...e)
}

function info(...e) {//34 - dark blue
  console.log("\x1b[36mInfo: \x1b[37m", ...e)
}

function warn(...e) {
  console.warn("\x1b[33mWarning:\x1b[37m", ...e)
}

function error(...e) {
  console.error("\x1b[31mError:\x1b[37m", ...e)
}