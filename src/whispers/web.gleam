import birl
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/list
import gleam/string
import gleam/string_builder.{type StringBuilder}
import nakai
import nakai/attr
import nakai/html
import whispers/holder
import wisp

pub type Context {
  Context(static_directory: String, my_holder: process.Subject(holder.Message))
}

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

pub fn full_page() -> StringBuilder {
  html.div(
    [
      attr.class("pane"),
      attr.Attr("hx-get", "/quote"),
      attr.Attr("hx-trigger", "load, every 15s"),
      attr.Attr("hx-swap", "innerHTML swap:2s"),
    ],
    [
      html.Head([
        html.meta([attr.http_equiv("X-UA-Compatible"), attr.content("IE=edge")]),
        html.meta([
          attr.name("viewport"),
          attr.content("width=device-width, initial-scale=1"),
        ]),
        html.title("Whispers in the Dark"),
        html.link([attr.rel("icon"), attr.href("static/img/favicon.png")]),
        html.link([attr.rel("stylesheet"), attr.href("static/css/space.css")]),
        html.Element("script", [attr.src("static/js/htmx.min.js")], []),
      ]),
    ],
  )
  |> nakai.to_string_builder
}

pub fn quote_html(ctx: Context) -> StringBuilder {
  let text = case process.call(ctx.my_holder, holder.Get, 100) {
    Ok(v) -> v
    Error(Nil) -> "No message available"
  }

  html.Fragment([html.div([attr.class("content")], [html.Text(text)])])
  |> nakai.to_inline_string_builder
}

pub fn quote_text(ctx: Context) -> String {
  case process.call(ctx.my_holder, holder.Get, 100) {
    Ok(v) -> v <> "\n"
    Error(Nil) -> "No message available\n"
  }
}

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

  [
    birl.to_iso8601(now),
    " ",
    client_ip,
    " ",
    int.to_string(response.status),
    " ",
    string.uppercase(http.method_to_string(req.method)),
    " ",
    req.path,
  ]
  |> string.concat
  |> wisp.log_info
  response
}
