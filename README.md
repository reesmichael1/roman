# Roman

A simple CLI RSS feed reader.

## Installation

`roman` is written in [Nim](https://nim-lang.org). Binaries are not yet available, so you will need to build from source. With `nim 0.20` installed, you should simply need to run `nimble build`. 

`roman` uses [`html2text`](http://alir3z4.github.io/html2text/) to display post bodies. You will need to have it installed on your system.

## Usage

To subscribe to feeds, use the `--subscribe` flag. For example, 

```
roman --subscribe https://feedwebsite.com/feed.rss
```

Then, when you run `roman`, you will be able to select a feed and post to view. Unread posts are marked as `[*]`. 

When reading a post, you can (by default) press `L` to construct a list of all of the links in the post you are viewing. After selecting one, the link will be opened in your default browser.

`roman` is still in very early development. Several improvements are planned!

## Configuration

You will need to copy the `config/config` file in this repository to `roman/config` within your platform's standard config directory. You can change the values in the file to your taste. 

## Platforms

Cross-platform support is fully intended, but for now, `roman` is only tested on Linux. (Most of the code should work just fine, but some filepaths that are generated are currently Linux-only. A patch would be happily accepted!)

## Contributing

Contributions are welcome! Please send patches, questions, requests, etc. to my [public inbox](mailto:~reesmichael1/public-inbox@lists.sr.ht).

Bug reports and feature requests may also be filed at the [project ticket tracker](https://todo.sr.ht/~reesmichael1/roman).
