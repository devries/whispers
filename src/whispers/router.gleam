import gleam/http.{Get}
import whispers/web.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> main_page(req)
    ["quote"] -> quote_response(req, ctx)
    _ -> wisp.not_found()
  }
}

fn main_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let html = web.full_page()
  wisp.ok()
  |> wisp.html_body(html)
}

fn quote_response(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Get)

  let fragment = web.quote_html(ctx)
  wisp.ok()
  |> wisp.set_header("cache-control", "no-cache, no-store")
  |> wisp.html_body(fragment)
}
