// Parser for bluesky jetstream post messages.

import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

// There are a number of posts, the ones we are interested
// in have a commit field which contains a record field. 
// Originally I was going to make it so these could parse every
// message that comes in. It parses the most common messages, but
// I don't care about the ones it wont parse. I will revisit this
// if I need more functionality.
pub type BlueskyPost {
  BlueskyPost(
    did: String,
    time_us: Int,
    kind: String,
    commit: Option(BlueskyCommit),
  )
}

pub type BlueskyCommit {
  BlueskyCommit(operation: String, record: Option(BlueskyRecord))
}

pub type BlueskyRecord {
  BlueskyRecord(rtype: String, langs: List(String), text: String)
}

pub fn record_decoder(
  v: dynamic.Dynamic,
) -> Result(BlueskyRecord, List(dynamic.DecodeError)) {
  dynamic.decode3(
    BlueskyRecord,
    dynamic.field("$type", of: dynamic.string),
    dynamic.field("langs", of: dynamic.list(dynamic.string)),
    dynamic.field("text", of: dynamic.string),
  )(v)
}

pub fn commit_decoder(
  v: dynamic.Dynamic,
) -> Result(BlueskyCommit, List(dynamic.DecodeError)) {
  dynamic.decode2(
    BlueskyCommit,
    dynamic.field("operation", of: dynamic.string),
    dynamic.optional_field("record", of: record_decoder),
  )(v)
}

// This should yield a post structure from the JSON message, but
// often gives a decode error because my structures don't handle
// all the message types.
pub fn post_from_json(
  json_string: String,
) -> Result(BlueskyPost, json.DecodeError) {
  let decoder =
    dynamic.decode4(
      BlueskyPost,
      dynamic.field("did", of: dynamic.string),
      dynamic.field("time_us", of: dynamic.int),
      dynamic.field("kind", of: dynamic.string),
      dynamic.optional_field("commit", of: commit_decoder),
    )

  json.decode(from: json_string, using: decoder)
}

// This function extracts the text from a post (if present) and
// filters it in the following ways:
// - Checks that one of the languages is specified as english
// - Checks that the text has no newline characters
// - Checks that the text is between 10 and 180 characters.
pub fn get_filtered_text(post: BlueskyPost) -> Result(String, Nil) {
  use commit <- result.try(option.to_result(post.commit, Nil))
  use record <- result.try(option.to_result(commit.record, Nil))

  let text_result = case list.find(record.langs, string.starts_with(_, "en")) {
    Ok(_) -> Ok(record.text)
    _ -> Error(Nil)
  }
  use text <- result.try(text_result)

  let singleline_result = case string.contains(does: text, contain: "\n") {
    True -> Error(Nil)
    False -> Ok(text)
  }
  use singleline <- result.try(singleline_result)

  case string.length(singleline) {
    x if x > 180 || x < 10 -> Error(Nil)
    _ -> Ok(text)
  }
}
