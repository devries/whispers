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

const japanese_post = "{\"did\":\"did:plc:twksn5rslmdht57uwemuc4nw\",\"time_us\":1736180321915908,\"kind\":\"commit\",\"commit\":{\"rev\":\"3lf3jxoszuh2z\",\"operation\":\"create\",\"collection\":\"app.bsky.feed.post\",\"rkey\":\"3lf3jxosszp2z\",\"record\":{\"$type\":\"app.bsky.feed.post\",\"createdAt\":\"2025-01-06T16:18:40.3023553Z\",\"embed\":{\"$type\":\"app.bsky.embed.external\",\"external\":{\"description\":\"沖縄県浦添市にあるアットホームなピアノ教室。グランドピアノを備えた広いレッスンルームで丁寧な指導を提供。技術向上と音楽の楽しさを学べる。\",\"thumb\":{\"$type\":\"blob\",\"ref\":{\"$link\":\"bafkreihj2wliydctc4liusxoa6gy2yvoouyfplezudhoagoczo6ud3sgry\"},\"mimeType\":\"image/webp\",\"size\":128362},\"title\":\"こすもすピアノ教室（沖縄県/個人・レッスン）\",\"uri\":\"https://www.music-school.net/web/detail/22635\"}},\"facets\":[{\"features\":[{\"$type\":\"app.bsky.richtext.facet#link\",\"tag\":null,\"uri\":\"https://www.music-school.net/web/detail/22635\"}],\"index\":{\"byteEnd\":355,\"byteStart\":310}},{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"沖縄ピアノ教室\",\"uri\":null}],\"index\":{\"byteEnd\":283,\"byteStart\":261}},{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"音楽教育\",\"uri\":null}],\"index\":{\"byteEnd\":297,\"byteStart\":284}},{\"features\":[{\"$type\":\"app.bsky.richtext.facet#tag\",\"tag\":\"発表会\",\"uri\":null}],\"index\":{\"byteEnd\":308,\"byteStart\":298}}],\"text\":\"こすもすピアノ教室（個人・レッスン）\\n沖縄県浦添市にあるアットホームなピアノ教室。グランドピアノを備えた広いレッスンルームで丁寧な指導を提供。技術向上と音楽の楽しさを学べる。\\n\\n#沖縄ピアノ教室\\n#音楽教育\\n#発表会\\n\\nhttps://www.music-school.net/web/detail/22635\\n\"},\"cid\":\"bafyreid4icpjx6ybuh557wmpluyr324ekl33kqyhsuf26zidox5brzh6ki\"}}"

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

pub fn japanese_post_decode_test() {
  message_parser.post_from_json(japanese_post)
  |> should.be_ok()
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
