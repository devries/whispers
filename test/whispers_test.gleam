import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import whispers/message_parser

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn post_decode_test() {
  let testpost =
    "{\"did\":\"did:plc:cswpqxequ5cym53m4twheqgx\",\"time_us\":1731877159475723,\"type\":\"com\",\"kind\":\"commit\",\"commit\":{\"rev\":\"3lb6cdfvsqb2v\",\"type\":\"c\",\"operation\":\"create\",\"collection\":\"app.bsky.feed.post\",\"rkey\":\"3lb6c7urcrc2v\",\"record\":{\"$type\":\"app.bsky.feed.post\",\"createdAt\":\"2024-11-17T20:57:18.433Z\",\"langs\":[\"en\"],\"reply\":{\"parent\":{\"cid\":\"bafyreiczi6nibxm5z2ywgudua7fy5utf5k72rdorgdxsxbclvi3ygp34j4\",\"uri\":\"at://did:plc:cmqrqadn4ognzhx6yrbsvirc/app.bsky.feed.post/3lb6bzx5smc27\"},\"root\":{\"cid\":\"bafyreif57qugp6chul5b4ralup6pixopkmjcpw2wdvbal6warjxhhmcpym\",\"uri\":\"at://did:plc:b3ethzamzumrezs4y7pibj6b/app.bsky.feed.post/3lb5glulh5s2w\"}},\"text\":\"😂😂 omg I’m sorry, I didn’t mean to call you out. Is your air sign Libra?\"},\"cid\":\"bafyreie52i76oyhow3i6nvkps747n3jfgjlvhqwcs5vl5vxfgsuso7ehim\"}}"

  let assert Ok(parsed) = message_parser.post_from_json(testpost)
  let assert Some(commit) = parsed.commit
  let assert Some(record) = commit.record
  record.langs |> should.equal(["en"])
  record.rtype |> should.equal("app.bsky.feed.post")
  record.text
  |> should.equal(
    "😂😂 omg I’m sorry, I didn’t mean to call you out. Is your air sign Libra?",
  )
}

pub fn account_decode_test() {
  let testpost =
    "{\"did\":\"did:plc:fnpimxwqlzlvuminrmi75uef\",\"time_us\":1731877159469157,\"type\":\"acc\",\"kind\":\"account\",\"account\":{\"active\":true,\"did\":\"did:plc:fnpimxwqlzlvuminrmi75uef\",\"seq\":3783151956,\"time\":\"2024-11-17T20:55:49.023Z\"}}"

  let assert Ok(parsed) = message_parser.post_from_json(testpost)
  parsed.kind |> should.equal("account")
  parsed.commit |> should.equal(None)
}

pub fn delete_decode_test() {
  let testpost =
    "{\"did\":\"did:plc:3oar65whvsdaxcnwniqthtju\",\"time_us\":1731877159220103,\"type\":\"com\",\"kind\":\"commit\",\"commit\":{\"rev\":\"3lb6cdgpo7y2b\",\"type\":\"d\",\"operation\":\"delete\",\"collection\":\"app.bsky.feed.post\",\"rkey\":\"3lb6ccogqzs2i\"}}"

  let assert Ok(parsed) = message_parser.post_from_json(testpost)
  let assert Some(commit) = parsed.commit
  commit.operation |> should.equal("delete")
  commit.record |> should.equal(None)
}
