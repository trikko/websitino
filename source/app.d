/*
MIT License

Copyright (c) 2025-2026 Andrea Fontana

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

module app;

import std;
import serverino;

string pathToServe;
string fileToServe;
string user;
string pass;

bool serveHidden;
bool listDirectories;
bool singleFile;
bool enableLogging = false;
bool useIndexFile = false;

mixin ServerinoMain;

static if (!__traits(compiles, WEBSITINO_VERSION)) enum WEBSITINO_VERSION = i"unofficial build: $(__DATE__) $(__TIME__)".text;

// Serve the file or directory
@endpoint
auto staticServe(Request request, Output output)
{
	// Just a helper function to show errors
	auto showError(Output output, short status, string message)
	{
		output.status = status;
		output.addHeader("Content-Type", "text/plain");
		output ~= message ~ "\n";
		return Fallthrough.Yes;
	}

	// Check if authentication is required.
	if (user.empty == false || pass.empty == false)
	{
		if ((user.empty == false && request.user != user) || (pass.empty == false && request.password != pass))
		{
			output.addHeader("WWW-Authenticate", "Basic realm=\"websitino\"");
			return showError(output, 401, "Unauthorized");
		}
	}

	// We accept only GET requests.
	if (request.method != Request.Method.Get)
		return showError(output, 405, "Method not allowed.");

	// We don't want to serve hidden files if the serveHidden flag is not set.
	if (serveHidden == false && request.path.split("/").filter!(s => s.startsWith(".")).empty == false)
		return showError(output, 403, "Forbidden");

	// Which file user asked for?
	string toServe;
	try { toServe = buildNormalizedPath(pathToServe, "." ~ decode(request.path)); }
	catch (Exception e) { return showError(output, 400, "Bad request"); }

	// Check if the user asked for a file that is not in the root directory.
	// This should not happen, but just in case.
	if (toServe.canFind(pathToServe) == false)
		return showError(output, 403, "Forbidden");

	// If the file doesn't exist, return a 404.
	if (exists(toServe) == false)
		return showError(output, 404, "File not found.");

	// If the user asked for a file, serve it.
	if (isFile(toServe) == true)
	{
		// If user started websitino with a single file, but asked for a different file, return a 403.
		if (singleFile && (toServe != fileToServe))
			return showError(output, 403, "Forbidden. Serving a single file.");

		// Serve the file.
		string format = request.get.read("format", "false");

		if (toServe.endsWith(".md") && (format == "true" || format == "1" || format.empty))
		{
			// Create an HTML viewer for the markdown file
			output.addHeader("Content-Type", "text/html; charset=utf-8");

			static immutable html =
			(`<!DOCTYPE html>
				<html>
				<head>
				<meta charset="utf-8">
				<title>%TITLE%</title>
				<meta name="viewport" content="width=device-width, initial-scale=1.0">
				<script src="https://cdn.jsdelivr.net/npm/marked@18.0.0/lib/marked.umd.min.js"></script>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.9.0/github-markdown.min.css">
				<style>
					body { font-family: sans-serif; max-width: 800px; margin: 2em auto; line-height: 1.5; padding: 0 15px; }
					pre { background-color: #f5f5f5; padding: 1em; border-radius: 5px; overflow-x: auto; }
					code { background-color: #f5f5f5; padding: 0.2em 0.4em; border-radius: 3px; }
					img { max-width: 100%; }
				</style>
				</head>
				<body>
				<div class="markdown-body" id="content"></div>

				<script>
					fetch("%URL%")
						.then(res => res.text())
						.then(md => { document.getElementById("content").innerHTML = marked.parse(md); });
				</script>
				</body>
			</html>`).splitter("\n").map!(line => line.strip).join("");

			output ~= html.replace("%TITLE%", toServe.baseName).replace("%URL%", request.path);
		}
		else
			output.serveFile(toServe);
	}

	else
	{
		// If --index is set, serve the specified index file if it exists.
		if (useIndexFile)
		{
			string indexPath = buildNormalizedPath(toServe, "index.html");
			if (exists(indexPath) && isFile(indexPath))
			{
				// Serve the index file.
				output.serveFile(indexPath);
				return Fallthrough.Yes;
			}
		}

		// Helper function to format file size in a readable way.
		auto formatFileSize(size_t sz)
		{
			string sizeStr;

			// Format size in a readable way
			string[] suffixes = ["B", "KB", "MB", "GB", "TB"];
			int suffixIndex;
			double displaySize = sz;

			for (suffixIndex = 0; displaySize >= 1024 && suffixIndex < suffixes.length - 1; suffixIndex++) {
				displaySize /= 1024.0;
			}

			sizeStr = (suffixIndex == 0) ?
				format("%d %s", cast(int)displaySize, suffixes[suffixIndex]) :
				format("%.1f %s", displaySize, suffixes[suffixIndex]);

			// Add padding to align all sizes
			sizeStr = rightJustify(sizeStr, 9);
			return sizeStr;
		}

		// If the user asked for a directory listing, but the listDirectories flag is not set, return a 403.
		if (listDirectories == false)
			return showError(output, 403, "Forbidden. Directory listing is disabled.\nTry running websitino with the --list-dirs or -l option.");

		// Check if the request comes from a browser or CLI
		auto userAgent = request.header.read("user-agent").toLower;

		// Probably we could just check for "mozilla" :)
		bool isBrowser =
			userAgent.canFind("mozilla") || userAgent.canFind("chrome") ||
			userAgent.canFind("safari") || userAgent.canFind("edge") ||
			userAgent.canFind("opera");

		// Collect and separate directories and files
		DirEntry[] directories;
		DirEntry[] files;

		foreach(entry; dirEntries(toServe, SpanMode.shallow))
		{
			// Skip hidden files if not requested
			if (!serveHidden && entry.name.baseName.startsWith("."))
				continue;

			if (entry.isDir) directories ~= entry;
			else files ~= entry;
		}

		// Sort directories by name
		directories.sort!((a, b) => a.name.baseName < b.name.baseName);

		// Sort files by name
		files.sort!((a, b) => a.name.baseName < b.name.baseName);

		string relativePath = toServe.length > pathToServe.length ? toServe[pathToServe.length..$] : "/";

		// If not a browser, return a simple but fancy list!
		if (!isBrowser)
		{
			output.addHeader("Content-Type", "text/plain; charset=utf-8");

			output ~= i"\n Directory listing for $(relativePath)\n\n".text;

			// First show directories
			foreach(entry; directories)
				output ~= "           📁 " ~ entry.name.baseName ~ "\n";

			// Then files
			foreach(entry; files)
				output ~= " " ~ formatFileSize(entry.size) ~ " 📄 " ~ entry.name.baseName ~ "\n";

			// Add a footer with a link to the websitino project.
			output ~= "\n Served with ♥  by websitino [ https://github.com/trikko/websitino ]\n\n";
		}
		else
		{
			// Create HTML page header
			output.addHeader("Content-Type", "text/html; charset=utf-8");

			// Start building the HTML page
			string html = i"<!DOCTYPE html><html><head><title>Directory listing for $(relativePath)</title>".text;

			// Add the viewport meta tag for responsive design
			html ~= "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";

			static immutable style =
			`<style>
				body{font-family:sans-serif;max-width:800px;margin:2em auto;line-height:1.5;padding:0 15px}
				a{text-decoration:none}
				.entry{display:grid;grid-template-columns:2em 1fr 8em;margin-bottom:0.5em}
				@media (max-width: 480px) {
					.entry{grid-template-columns:2em 1fr 5em}
					body{margin:1em auto}
					h1{font-size:1.5em}
				}
				.size{text-align:right}
				.filename{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
				footer{text-align:center;margin-top:2em;color:#666;font-size:0.9em}
			</style>`.splitter("\n").map!(line => line.strip).join("");

			html ~= style;
			html ~= "</head><body>";
			html ~= "<h1>📁 " ~ relativePath ~ "</h1><hr>";

			// Always add link to parent directory
			html ~= "<div class='entry'>";
			html ~= format("📁 <a href='%s'>..</a> <span class='size'></span>",
				request.path.dirName
			);
			html ~= "</div>";

			// First show directories
			foreach(entry; directories) {
				string name = entry.name.baseName;
				string link = request.path.buildPath(name);

				html ~= "<div class='entry'>";
				html ~= format("📁 <a href='%s' class='filename' title='%s'>%s</a> <span class='size'></span>",
					link,
					name,
					name
				);
				html ~= "</div>";
			}

			// Then files
			foreach(entry; files)
			{
				string name = entry.name.baseName;
				string link = request.path.buildPath(name);
				auto size = formatFileSize(entry.size);

				html ~= "<div class='entry'>";
				html ~= format("📄 <a href='%s' class='filename' title='%s'>%s</a> <span class='size'>%s</span>",
					link,
					name,
					name,
					size
				);
				html ~= "</div>";
			}

			html ~= "<footer>served with ❤️ by <a href='https://github.com/trikko/websitino'>websitino</a></footer>";
			html ~= "</body></html>";
			output ~= html;
		}
	}

	return Fallthrough.Yes;
}


// If logging is enabled, log the request.
@priority(-1) @endpoint
void logger(Request request, Output output)
{
	if (enableLogging)
		info(i"[$(output.status)] ⤇ $(request.path)");
}

// Serverino configuration and command line arguments parsing.
@onServerInit ServerinoConfig configure(string[] args)
{
	ushort port = 8123;
	string ip = string.init;
	string authString;

	bool showHelp;
	bool ipv6;

	// Parse the command line arguments using std.getopt looking for the --port option.
	try {
		showHelp = getopt(args,
			"6|ipv6", &ipv6,
			"a|auth", &authString,
			"b|bind", &ip,
			"p|port",  &port,
			"s|show-hidden", &serveHidden,
			"l|list-dirs", &listDirectories,
			"i|index", &useIndexFile,
			"v|verbose", &enableLogging,
		).helpWanted;
	}
	catch (Exception e) { showHelp = true; }

	// If the user asked for --help or the port is not set, show the usage and exit with code 1.
	if (showHelp)
	{
		// Enable terminal colors on older windows
      version(Windows)
      {
         import core.sys.windows.windows;

         DWORD dwMode;
         HANDLE hOutput = GetStdHandle(STD_OUTPUT_HANDLE);

         GetConsoleMode(hOutput, &dwMode);
         dwMode |= ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
         SetConsoleMode(hOutput, dwMode);
      }

		string help = "\n\x1b[32mwebsitino ("~ WEBSITINO_VERSION ~") \x1b[0m\nFile serving, simplified.\x1b[0m\n\n\x1b[32mUsage:\x1b[0m
websitino \x1b[2m[path] [options...]\x1b[0m

\x1b[32mOptions:\x1b[0m
 \x1b[1m --list-dirs   -l\x1b[0m                Show directory listings (default: disabled).
 \x1b[1m --index       -i\x1b[0m                Use index.html when browsing directories.
 \x1b[1m --show-hidden -s\x1b[0m                Serve hidden files (default: disabled).
 \x1b[1m --auth        -a\x1b[0m  <user:pass>   Set the authentication string. (default: disabled)
 \x1b[1m --port        -p\x1b[0m  <port>        Set the port to listen on. (default: 8123)
 \x1b[1m --bind        -b\x1b[0m  <ip_address>  Set the ip address to listen on. (default: 0.0.0.0)
 \x1b[1m --ipv6        -6\x1b[0m                Force IPv6 (default: IPv4).
 \x1b[1m --verbose     -v\x1b[0m                Enable request logging (default: disabled).
 \x1b[1m --help        -h\x1b[0m                Show this help.

\x1b[32mFeatures:\x1b[0m
 \x1b[1m Markdown rendering\x1b[0m              Add ?format to any .md file URL to render it as HTML.
";

		writeln(help);
		return ServerinoConfig.create().setReturnCode(1);
	}

	if (args.length > 2)
	{
		writeln(i"\x1b[31mError:\x1b[0m too many arguments. Run \x1b[1m$(args[0].baseName) --help\x1b[0m for more information.");
		return ServerinoConfig.create().setReturnCode(1);
	}

	if (args.length == 2)
		pathToServe = args[1];

	pathToServe = buildNormalizedPath(getcwd(), pathToServe);

	if (!exists(pathToServe))
	{
		writeln(i"\x1b[31mError:\x1b[0m path to serve does not exist. Run \x1b[1m$(args[0].baseName) --help\x1b[0m for more information.");
		return ServerinoConfig.create().setReturnCode(1);
	}

	if (ip.count(':') > 1) ipv6 = true;

	if (ip.empty)
	{
		if (ipv6) ip = "::";
		else ip = "0.0.0.0";
	}

	singleFile = isFile(pathToServe);

	environment["WEBSITINO_SINGLE_FILE"] = singleFile.to!string;
	environment["WEBSITINO_AUTH"] = authString;
	environment["WEBSITINO_HIDDEN"] = serveHidden.to!string;
	environment["WEBSITINO_LIST_DIRS"] = listDirectories.to!string;
	environment["WEBSITINO_PATH"] = pathToServe;
	environment["WEBSITINO_LOGGING"] = enableLogging.to!string;
	environment["WEBSITINO_INDEX"] = useIndexFile.to!string;


	// Return the configuration for the serverino with the port set by the user.
	auto config = ServerinoConfig.create()
		.setLogLevel(LogLevel.info)
		.setMaxRequestTime(100.msecs)
		.setMaxRequestSize(1024)
		.setMaxDynamicWorkerIdling(15.seconds)
		.setMinWorkers(0)
		.setMaxWorkers(5);


	if (ipv6) config.addListener!(ServerinoConfig.ListenerProtocol.IPV6)(ip, port);
	else config.addListener!(ServerinoConfig.ListenerProtocol.IPV4)(ip, port);

	return config;
		
}


// Configure a new worker
@onWorkerStart
void config()
{
	// Data passed from the daemon
	pathToServe = environment["WEBSITINO_PATH"];
	serveHidden = environment["WEBSITINO_HIDDEN"].to!bool;
	listDirectories = environment["WEBSITINO_LIST_DIRS"].to!bool;
	singleFile = environment["WEBSITINO_SINGLE_FILE"].to!bool;
	enableLogging = environment["WEBSITINO_LOGGING"].to!bool;
	useIndexFile = environment["WEBSITINO_INDEX"].to!bool;

	if (singleFile)
	{
		fileToServe = pathToServe;
		pathToServe = dirName(pathToServe);
	}

	if ("WEBSITINO_AUTH" in environment)
	{
		auto auth = environment["WEBSITINO_AUTH"].split(":");

		if (auth.length > 0) user = auth[0];
		if (auth.length > 1) pass = auth[1..$].join(":");
	}
}
