// Parser for bluesky jetstream post messages.

import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
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

pub fn get_english_post_text(post: BlueskyPost) -> Result(String, Nil) {
  case post.commit {
    None -> Error(Nil)
    Some(commit) -> {
      case commit.record {
        None -> Error(Nil)
        Some(record) -> {
          case list.find(record.langs, string.starts_with(_, "en")) {
            Ok(_) -> Ok(record.text)
            _ -> Error(Nil)
          }
        }
      }
    }
  }
}

pub fn filter_length_lines(in: Result(String, Nil)) -> Result(String, Nil) {
  case in {
    Error(Nil) -> Error(Nil)
    Ok(text) -> {
      case string.contains(does: text, contain: "\n") {
        True -> Error(Nil)
        False -> {
          case string.length(text) {
            x if x > 180 || x < 10 -> Error(Nil)
            _ -> Ok(text)
          }
        }
      }
    }
  }
}
