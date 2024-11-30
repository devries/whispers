import birl
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/string_tree.{type StringTree}
import nakai
import nakai/attr
import nakai/html
import whispers/holder
import wisp

pub type Context {
  Context(static_directory: String, my_holder: process.Subject(holder.Message))
}

// The middleware hangs on to the context and set up logging and some defaults
// as well as logging. It also serves the static content.
pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- detail_log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

// I am using nakai to build my HTML. This is a relatively simple main index
// page.
pub fn full_page() -> StringTree {
  let url = "https://whispers.unnecessary.tech"
  let title = "Whispers in the Dark"
  let description = "Real-time text-only posts from Bluesky"
  let image_url = url <> "/static/img/whispers.png"

  html.div(
    [
      attr.class("pane"),
      attr.Attr("hx-get", "/quote"),
      attr.Attr("hx-trigger", "load, every 15s"),
      attr.Attr("hx-swap", "innerHTML swap:2s"),
    ],
    [
      html.Head([
        // Boilderplate
        html.meta([attr.http_equiv("X-UA-Compatible"), attr.content("IE=edge")]),
        html.meta([
          attr.name("viewport"),
          attr.content("width=device-width, initial-scale=1"),
        ]),
        html.title(title),
        // Opengraph/twitter stuff
        html.meta([attr.name("og:url"), attr.content(url)]),
        html.meta([attr.name("og:type"), attr.content("website")]),
        html.meta([attr.name("title"), attr.content(title)]),
        html.meta([attr.name("og:title"), attr.content(title)]),
        html.meta([attr.name("twitter:title"), attr.content(title)]),
        html.meta([attr.name("og:site_name"), attr.content(title)]),
        html.meta([attr.name("description"), attr.content(description)]),
        html.meta([attr.name("twitter:description"), attr.content(description)]),
        html.meta([attr.name("og:description"), attr.content(description)]),
        html.meta([
          attr.name("twitter:card"),
          attr.content("summary_large_image"),
        ]),
        html.meta([attr.name("twitter:image"), attr.content(image_url)]),
        html.meta([attr.name("og:image"), attr.content(image_url)]),
        html.link([attr.rel("icon"), attr.href("static/img/favicon.png")]),
        // Useful stuff
        html.link([attr.rel("stylesheet"), attr.href("static/css/space.css")]),
        html.Element("script", [attr.src("static/js/htmx.min.js")], []),
      ]),
    ],
  )
  |> nakai.to_string_tree
}

// This HTML fragment has the post text within a div with a class attribute
// for styling. It's also built with nakai.
pub fn quote_html(ctx: Context) -> StringTree {
  let text = case process.call(ctx.my_holder, holder.Get, 100) {
    Ok(v) -> v
    Error(Nil) -> "No message available"
  }

  html.Fragment([html.div([attr.class("content")], [html.Text(text)])])
  |> nakai.to_inline_string_tree
}

// I also decided it might be fun to just grab the text. I add a newline so
// that I can display it easily in bash. 
pub fn quote_text(ctx: Context) -> String {
  case process.call(ctx.my_holder, holder.Get, 100) {
    Ok(v) -> v <> "\n"
    Error(Nil) -> "No message available\n"
  }
}

// For logging I assume this exists behind a proxy so I can pull the IP address
// from the X-Forwarded-For header. I log at the info level the date, IP, response
// status code, request method, and path.
pub fn detail_log_request(
  req: wisp.Request,
  handler: fn() -> wisp.Response,
) -> wisp.Response {
  let response = handler()

  let now = birl.now()

  let client_ip = {
    case list.key_find(req.headers, "x-forwarded-for") {
      Ok(ip) -> ip
      Error(_) -> "unknown_ip"
    }
  }

  let user_agent = request.get_header(req, "user-agent") |> result.unwrap("")
  let response_size = case get_body_size(response.body) {
    Ok(n) -> int.to_string(n)
    Error(Nil) -> "Unknown"
  }

  [
    birl.to_iso8601(now),
    " ",
    client_ip,
    " - ",
    string.uppercase(http.method_to_string(req.method)),
    " ",
    req.path,
    " ",
    int.to_string(response.status),
    " ",
    response_size,
    " \"",
    user_agent,
    "\"",
  ]
  |> string.concat
  |> wisp.log_info
  response
}

fn get_body_size(body: wisp.Body) -> Result(Int, Nil) {
  case body {
    wisp.Text(sb) -> Ok(string_tree.byte_size(sb))
    wisp.Bytes(bb) -> Ok(bytes_tree.byte_size(bb))
    wisp.File(_) -> Error(Nil)
    wisp.Empty -> Ok(0)
  }
}
