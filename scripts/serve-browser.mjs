import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize, resolve, sep } from "node:path";

const root = process.cwd();
const preferredPort = Number(process.env.PORT ?? "8081");

const contentTypes = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".map": "application/json; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
};

function filePathForUrl(url) {
  const parsed = new URL(url, `http://localhost:${preferredPort}`);
  const pathname = parsed.pathname === "/" ? "/public/" : parsed.pathname;
  const relative = normalize(decodeURIComponent(pathname)).replace(/^(\.\.[/\\])+/, "");
  let filePath = resolve(root, `.${sep}${relative}`);
  if (!filePath.startsWith(root + sep) && filePath !== root) {
    return undefined;
  }
  if (existsSync(filePath) && statSync(filePath).isDirectory()) {
    filePath = join(filePath, "index.html");
  }
  return filePath;
}

function makeServer() {
  return createServer((req, res) => {
    const filePath = filePathForUrl(req.url ?? "/");
    if (!filePath || !existsSync(filePath) || !statSync(filePath).isFile()) {
      res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      res.end("Not found\n");
      return;
    }

    res.writeHead(200, {
      "content-type": contentTypes[extname(filePath)] ?? "application/octet-stream",
      "cache-control": "no-store",
    });
    createReadStream(filePath).pipe(res);
  });
}

function listen(port, attemptsLeft = 10) {
  const server = makeServer();

  server.once("error", (error) => {
    if (error.code === "EADDRINUSE" && attemptsLeft > 0 && !process.env.PORT) {
      listen(port + 1, attemptsLeft - 1);
      return;
    }
    throw error;
  });

  server.listen(port, () => {
    console.log(`RhodoniteMBT browser sample: http://localhost:${port}/public/`);
  });
}

listen(preferredPort);
