import gleam/erlang/process
import gleam/http/request
import gleam/int
import gleam/io
import gleam/option.{None}
import gleam/otp/actor
import gleam/string
import mist
import stratus
import whispers/holder
import whispers/message_parser
import whispers/router
import whispers/web.{Context}
import wisp
import wisp/wisp_mist

pub fn main() {
  io.println("Starting")

  // Holder is an actor what will keep the latest post from bluesky
  let assert Ok(my_holder) = holder.new()

  // Create websocket connection to stream the posts from bluesky.
  let assert Ok(req) =
    request.to("https://jetstream1.us-east.bsky.network/subscribe")
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
                // The post will be filtered for length, style, and language
                case message_parser.get_filtered_text(post) {
                  Ok(text) -> process.send(my_holder, holder.Put(text))
                  Error(Nil) -> Nil
                }
              }
              Error(_e) -> Nil
            }
            actor.continue(state)
          }
          _ -> actor.continue(state)
        }
      },
    )
    |> stratus.on_close(fn(_state) {
      io.println("Websocket closed")
      // In case of a socket disconnect, leave a message indicating the
      // error on the website. Will explore reconnecting at some point.
      process.send(
        my_holder,
        holder.Put("I seem to have lost my connection to Bluesky 😢."),
      )
    })

  let assert Ok(_subj) = stratus.initialize(builder)

  // Set up the web server process
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let ctx = Context(static_directory: static_directory(), my_holder: my_holder)
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.bind("::")
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
  // get_values_slowly(my_holder, 2000)
}

// This is a debug function to periodically print messages from the holder.
fn get_values_slowly(
  my_holder: process.Subject(holder.Message),
  sleep_time: Int,
) {
  process.sleep(sleep_time)
  case process.call(my_holder, holder.Get, 100) {
    Ok(text) -> io.println(int.to_string(string.length(text)) <> ": " <> text)
    Error(Nil) -> io.println("No message available")
  }
  get_values_slowly(my_holder, sleep_time)
}

// Static directory locator for wisp.
pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("whispers")
  priv_directory <> "/static"
}
