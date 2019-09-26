use std::error::Error;
use std::fmt;
use std::fs::File;
use std::path::{Path, PathBuf};

use directories::ProjectDirs;
use question::Question;
use rss::Channel;
use serde::Deserialize;

#[derive(Clone, Deserialize, Debug)]
struct Subscription {
    url: String,
    name: String,
}

#[derive(Debug)]
struct RomanError {
    details: String,
}

#[derive(Debug)]
struct Feed {
    posts: Vec<Post>,
    title: String,
    unread_posts: i32,
}

impl Feed {
    pub fn from_channel(channel: &Channel) -> Feed {
        Feed {
            posts: vec![],
            title: String::from(channel.title()),
            unread_posts: 10,
        }
    }
}

#[derive(Debug)]
struct Post {
    title: String,
    rendered: String,
    raw: String,
    guid: String,
    read: bool,
    author: Option<String>,
}

impl RomanError {
    fn new(msg: &str) -> RomanError {
        RomanError {
            details: msg.to_string(),
        }
    }
}

impl fmt::Display for RomanError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.details)
    }
}

impl Error for RomanError {
    fn description(&self) -> &str {
        &self.details
    }
}

fn get_subscriptions_path() -> Result<PathBuf, Box<Error>> {
    if let Some(project_dirs) = ProjectDirs::from("", "", "roman") {
        let path: PathBuf = [project_dirs.config_dir(), Path::new("subscriptions")]
            .iter()
            .collect();
        return Ok(path);
    }
    Err(Box::new(RomanError::new(
        "could not load subscriptions file",
    )))
}

pub fn subscribe(url: &str) {
    dbg!(url);
}

fn load_feed(sub: &Subscription) -> Result<Feed, Box<dyn Error>> {
    let channel = Channel::from_url(&sub.url)?;
    Ok(Feed::from_channel(&channel))
}

pub fn run() -> Result<(), Box<dyn Error>> {
    let path = get_subscriptions_path()?;
    let subs_file = File::open(path)?;

    let mut rdr = csv::Reader::from_reader(subs_file);
    let mut subs = vec![];
    for result in rdr.deserialize() {
        let record: Subscription = result?;
        subs.push(record);
    }

    let mut feeds = vec![];

    for sub in subs {
        feeds.push(load_feed(&sub)?);
    }

    let feed = choose_feed(feeds);

    Ok(())
}

fn choose_feed(feeds: Vec<Feed>) -> Feed {
    feeds[0]
}
