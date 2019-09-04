# Roman

A simple CLI RSS feed reader.

## Installation

`roman` is written in [Nim](https://nim-lang.org). Binaries are not yet available, so you will need to build from source. With `nim 0.20` installed, you should simply need to run `nimble build`. 

`roman` uses a patched version of [`html2text`](https://github.com/jugglerchris/rust-html2text) to display post bodies. You will need to have [Rust](https://rust-lang.org) installed to build this as well. 

```
git clone https://github.com/jugglerchris/rust-html2text
cd rust-html2text
# copy patches/html2text.patch from this repository to rust-html2text
patch -p1 < html2text.patch 
cargo build --release
```

Then, copy `target/release/libhtml2text.so` to somewhere where your linker can find it. 

## Usage

Currently, `roman` only displays the current entries available in a feeds the user is subscribed to.

To subscribe to feeds, use the `--subscribe` flag. For example, 

```
roman --subscribe https://feedwebsite.com/feed.rss
```

Then, when you run `roman`, you will be able to select a feed and post to view.

Several improvements are planned, such as keeping track of read/unread posts.

## Contributing

Contributions are welcome! Please send patches, questions, requests, etc. to my [public inbox](mailto:~reesmichael1/public-inbox@lists.sr.ht).
