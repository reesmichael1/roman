# Roman

A simple CLI RSS feed reader.

## Installation

`roman` is written in [Rust](https://rust-lang.org). Binaries are not yet available, so you will need to build from source using `cargo`.

## Usage

To subscribe to feeds, use the `--subscribe` flag. For example, 

```
roman --subscribe https://feedwebsite.com/feed.rss
```

Then, when you run `roman`, you will be able to select a feed and post to view. Unread posts are marked as `[*]`. 

`roman` is still in very early development. Several improvements are planned!

## Configuration

You will need to copy the `config/config` file in this repository to `roman/config` within your platform's standard config directory. You can change the values in the file to your taste. 

## Platforms

Cross-platform support is fully intended, but for now, `roman` is only tested on Linux. Any patches improving support on other platforms would be happily accepted!

## Contributing

Contributions are welcome! Please send patches, questions, requests, etc. to my [public inbox](mailto:~reesmichael1/public-inbox@lists.sr.ht).
