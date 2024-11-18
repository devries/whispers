import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type Message {
  Put(text: String)
  Get(reply_with: Subject(Result(String, Nil)))
  Shutdown
}

pub fn handle_message(message: Message, current: Result(String, Nil)) {
  case message {
    Put(text) -> actor.continue(Ok(text))
    Get(client) -> {
      process.send(client, current)
      actor.continue(current)
    }
    Shutdown -> actor.Stop(process.Normal)
  }
}
