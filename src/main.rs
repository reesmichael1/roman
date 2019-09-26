extern crate clap;

use std::process;

use clap::{App, Arg, SubCommand};

fn main() {
    let matches = App::new("roman")
        .version("0.1.0")
        .about("A simple RSS feed reader")
        .author("Michael Rees")
        .subcommand(
            SubCommand::with_name("subscribe")
                .about("subscribe to an RSS feed")
                .arg(Arg::with_name("URL").required(true)),
        )
        .get_matches();

    if let Some(matches) = matches.subcommand_matches("subscribe") {
        let url = matches.value_of("URL").expect("required URL argument");
        roman::subscribe(url);
    } else {
        if let Err(err) = roman::run() {
            eprintln!("application error: {}", err);
            process::exit(1);
        };
    }
}
