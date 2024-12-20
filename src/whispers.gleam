import birl
import gleam/erlang/process
import gleam/http/request
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist
import promgleam/metrics/counter.{create_counter, increment_counter}
import stratus
import whispers/holder
import whispers/message_parser
import whispers/router
import whispers/web.{Context}
import wisp
import wisp/wisp_mist

pub fn main() {
  // We'll start out with the wisp logger so we can use it throughout
  // the program
  wisp.configure_logger()
  // Uncomment below for debug logging
  // wisp.set_logger_level(wisp.DebugLevel)

  log_info("Starting")

  // Now let's stop when we get an interrupt signal

  // Create a prometheus counter to hold the count of posts
  let assert Ok(Nil) =
    create_counter(
      registry: "default",
      name: "bluesky_posts_total",
      help: "Total number of posts seen",
      labels: [],
    )

  // Holder is an actor what will keep the latest post from bluesky
  let assert Ok(my_holder) = holder.new()

  // Create websocket connection to stream the posts from bluesky.
  let assert Ok(req) =
    request.to("https://jetstream1.us-east.bsky.network/subscribe")
  let req =
    req
    |> request.set_header(
      "user-agent",
      "Whispers in the Dark (https://github.com/devries/whispers)",
    )
    |> request.set_query([#("wantedCollections", "app.bsky.feed.post")])

  new_websocket(req, my_holder)

  // Set up the web server process
  let secret_key_base = wisp.random_string(64)

  let ctx = Context(static_directory: static_directory(), my_holder: my_holder)
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.bind("::")
    |> mist.port(8080)
    |> mist.start_http

  log_info("Listening on port 8080")
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

// Websocket constructor
pub fn new_websocket(
  req: request.Request(String),
  my_holder: process.Subject(holder.Message),
) {
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
                let _ = increment_post_count(post)
                let tags = message_parser.get_tags(post)
                case list.length(tags) {
                  0 -> Nil
                  _ ->
                    log_debug(
                      "Tags: "
                      <> string.join(message_parser.get_tags(post), ", "),
                    )
                }
                case message_parser.get_filtered_text(post) {
                  Ok(text) -> process.send(my_holder, holder.Put(text))
                  Error(Nil) -> Nil
                }
              }
              Error(e) ->
                log_warning("Warning: " <> string.inspect(e) <> " on: " <> msg)
            }
            actor.continue(state)
          }
          _ -> actor.continue(state)
        }
      },
    )
    |> stratus.on_close(fn(_state) {
      log_warning("Websocket closed!")
      process.send(
        my_holder,
        holder.Put("I seem to have lost my connection to Bluesky 😢."),
      )

      process.sleep(1000)
      new_websocket(req, my_holder)
    })
    |> stratus.on_handshake_error(fn(_) {
      log_warning("Handshake error!")
      process.send(
        my_holder,
        holder.Put("I seem to have lost my connection to Bluesky 😢."),
      )

      process.sleep(10_000)
      new_websocket(req, my_holder)
    })

  log_info("Connecting to websocket")
  case stratus.initialize(builder) {
    Ok(_) -> Nil
    Error(socket_error) -> {
      log_warning(
        "Websocket initialization failure: " <> string.inspect(socket_error),
      )
      process.sleep(5000)
      new_websocket(req, my_holder)
    }
  }
}

fn log_debug(message: String) {
  let now = birl.now()

  [birl.to_iso8601(now), " ", message]
  |> string.concat
  |> wisp.log_debug
}

fn log_info(message: String) {
  let now = birl.now()

  [birl.to_iso8601(now), " ", message]
  |> string.concat
  |> wisp.log_info
}

fn log_warning(message: String) {
  let now = birl.now()

  [birl.to_iso8601(now), " ", message]
  |> string.concat
  |> wisp.log_warning
}

fn increment_post_count(post: message_parser.BlueskyPost) -> Result(Nil, Nil) {
  use commit <- result.try(option.to_result(post.commit, Nil))
  use _ <- result.try(option.to_result(commit.record, Nil))
  let _ =
    increment_counter(
      registry: "default",
      name: "bluesky_posts_total",
      labels: [],
      value: 1,
    )
  Ok(Nil)
}
