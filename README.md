# Roman

A simple CLI RSS feed reader.

## Installation

`roman` is written in [Nim](https://nim-lang.org). Binaries are not yet available, so you will need to build from source. With `nim 0.20` installed, you should simply need to run `nimble build`. 

## Usage

Currently, `roman` only displays the current entries available in a feed passed as a parameter. For example, 

```
roman https://website.tld/feed.rss

Post Title
Here is the entry of the post. 

Second Post
Here is another post.
```

Several improvements are planned, such as the ability to subscribe to feeds and mark posts as read.

## Contributing

Contributions are welcome! Please send patches, questions, requests, etc. to my [public inbox](mailto:~reesmichael1/public-inbox@lists.sr.ht).
