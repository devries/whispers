import gleam/erlang/process
import gleam/http/request
import gleam/io
import gleam/option.{None}
import gleam/otp/actor
import stratus
import whispers/message_parser

pub fn main() {
  io.println("Starting")

  let assert Ok(req) =
    request.to("https://jetstream2.us-east.bsky.network/subscribe")
  let req =
    req |> request.set_query([#("wantedCollections", "app.bsky.feed.post")])

  let builder =
    stratus.websocket(
      request: req,
      init: fn() { #(Nil, None) },
      loop: fn(msg, state, _conn) {
        case msg {
          stratus.Text(msg) -> {
            case message_parser.post_from_json(msg) {
              Ok(post) -> {
                case message_parser.get_english_post_text(post) {
                  Ok(text) -> io.println("POSTHERE: " <> text)
                  Error(Nil) -> Nil
                }
              }
              Error(_e) -> {
                // io.debug(e)
                // io.println(msg)
                Nil
              }
            }
            actor.continue(state)
          }
          _ -> actor.continue(state)
        }
      },
    )
    |> stratus.on_close(fn(_state) { io.println("Closed") })

  let assert Ok(_subj) = stratus.initialize(builder)

  process.sleep_forever()
}
