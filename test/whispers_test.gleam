import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import whispers/message_parser

pub fn main() {
  gleeunit.main()
}

const testpost_post = "{\"did\":\"did:plc:cswpqxequ5cym53m4twheqgx\",\"time_us\":1731877159475723,\"type\":\"com\",\"kind\":\"commit\",\"commit\":{\"rev\":\"3lb6cdfvsqb2v\",\"type\":\"c\",\"operation\":\"create\",\"collection\":\"app.bsky.feed.post\",\"rkey\":\"3lb6c7urcrc2v\",\"record\":{\"$type\":\"app.bsky.feed.post\",\"createdAt\":\"2024-11-17T20:57:18.433Z\",\"langs\":[\"en\"],\"reply\":{\"parent\":{\"cid\":\"bafyreiczi6nibxm5z2ywgudua7fy5utf5k72rdorgdxsxbclvi3ygp34j4\",\"uri\":\"at://did:plc:cmqrqadn4ognzhx6yrbsvirc/app.bsky.feed.post/3lb6bzx5smc27\"},\"root\":{\"cid\":\"bafyreif57qugp6chul5b4ralup6pixopkmjcpw2wdvbal6warjxhhmcpym\",\"uri\":\"at://did:plc:b3ethzamzumrezs4y7pibj6b/app.bsky.feed.post/3lb5glulh5s2w\"}},\"text\":\"😂😂 omg I’m sorry, I didn’t mean to call you out. Is your air sign Libra?\"},\"cid\":\"bafyreie52i76oyhow3i6nvkps747n3jfgjlvhqwcs5vl5vxfgsuso7ehim\"}}"

const testpost_account = "{\"did\":\"did:plc:fnpimxwqlzlvuminrmi75uef\",\"time_us\":1731877159469157,\"type\":\"acc\",\"kind\":\"account\",\"account\":{\"active\":true,\"did\":\"did:plc:fnpimxwqlzlvuminrmi75uef\",\"seq\":3783151956,\"time\":\"2024-11-17T20:55:49.023Z\"}}"

const testpost_delete = "{\"did\":\"did:plc:3oar65whvsdaxcnwniqthtju\",\"time_us\":1731877159220103,\"type\":\"com\",\"kind\":\"commit\",\"commit\":{\"rev\":\"3lb6cdgpo7y2b\",\"type\":\"d\",\"operation\":\"delete\",\"collection\":\"app.bsky.feed.post\",\"rkey\":\"3lb6ccogqzs2i\"}}"

const tagged_post = "{\"did\":\"did:plc:jkbczecxe4n5l36wbumr64kr\",\"time_us\":1732563223100851,\"type\":\"com\",\"kind\":\"commit\",\"commit\":{\"rev\":\"3lbsbbq5uvh2y\",\"type\":\"c\",\"operation\":\"create\",\"collection\":\"app.bsky.feed.post\",\"rkey\":\"3lbsbbnx5vs2q\",\"record\":{\"$type\":\"app.bsky.feed.post\",\"createdAt\":\"2024-11-25T19:33:39.417Z\",\"embed\":{\"$type\":\"app.bsky.embed.images\",\"images\":[{\"alt\":\"\",\"aspectRatio\":{\"height\":1592,\"width\":1740},\"image\":{\"$type\":\"blob\",\"ref\":{\"$link\":\"bafkreihcmtfdtvu7wyvl6cxldl7fnybxnrhkljeb2ttrktkvcfshyfcn24\"},\"mimeType\":\"image/jpeg\",\"size\":963304}}]},\"facets\":[{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"kidlitart\"}],\"index\":{\"byteEnd\":26,\"byteStart\":16}},{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"illustration\"}],\"index\":{\"byteEnd\":40,\"byteStart\":27}},{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"marker\"}],\"index\":{\"byteEnd\":48,\"byteStart\":41}},{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"ohuhu\"}],\"index\":{\"byteEnd\":55,\"byteStart\":49}},{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"arr\"}],\"index\":{\"byteEnd\":60,\"byteStart\":56}}],\"langs\":[\"en\"],\"text\":\"So... Topeica? \\n#kidlitart #illustration #marker #ohuhu #arr\"},\"cid\":\"bafyreibidxpb6krxukipjvkr5jcnlfldjjblca6vja2urhhddkx4pztkmq\"}}"

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn post_decode_test() {
  let assert Ok(parsed) = message_parser.post_from_json(testpost_post)
  let assert Some(commit) = parsed.commit
  let assert Some(record) = commit.record
  let assert Some(langs) = record.langs
  langs |> should.equal(["en"])
  record.rtype |> should.equal("app.bsky.feed.post")
  record.text
  |> should.equal(
    "😂😂 omg I’m sorry, I didn’t mean to call you out. Is your air sign Libra?",
  )
}

pub fn account_decode_test() {
  let assert Ok(parsed) = message_parser.post_from_json(testpost_account)
  parsed.kind |> should.equal("account")
  parsed.commit |> should.equal(None)
}

pub fn delete_decode_test() {
  let assert Ok(parsed) = message_parser.post_from_json(testpost_delete)
  let assert Some(commit) = parsed.commit
  commit.operation |> should.equal("delete")
  commit.record |> should.equal(None)
}

pub fn extract_text_test() {
  let assert Ok(parsed_post) = message_parser.post_from_json(testpost_post)
  message_parser.get_filtered_text(parsed_post)
  |> should.equal(Ok(
    "😂😂 omg I’m sorry, I didn’t mean to call you out. Is your air sign Libra?",
  ))

  let assert Ok(parsed_account) =
    message_parser.post_from_json(testpost_account)
  message_parser.get_filtered_text(parsed_account)
  |> should.equal(Error(Nil))

  let assert Ok(parsed_delete) = message_parser.post_from_json(testpost_delete)
  message_parser.get_filtered_text(parsed_delete)
  |> should.equal(Error(Nil))
}

pub fn extract_tags_test() {
  let assert Ok(parsed) = message_parser.post_from_json(tagged_post)

  message_parser.get_tags(parsed)
  |> should.equal(["kidlitart", "illustration", "marker", "ohuhu", "arr"])
}
