// Parser for bluesky jetstream post messages.

import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

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
