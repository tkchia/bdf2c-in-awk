// © 2020—2026 TK Chia
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0.  If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use anyhow::{anyhow, Result};
use clap::Parser;
use std::collections::BTreeMap;
use std::fs;
use std::io::{self, Read};
use std::path::PathBuf;

mod bdf_parser;
mod code_generator;
mod cp437_map;
mod options;

use bdf_parser::BdfParser;
use code_generator::CodeGenerator;
use options::Options;

const VERSION: &str = "0.1.0";
const REPO_URL: &str = "https://github.com/tkchia/bdf2c-in-awk";
const LICENSE: &str = "MPL-2.0";

#[derive(Parser, Debug)]
#[command(name = "bdf2c")]
#[command(about = "Convert Adobe BDF font files to C source/header files", long_about = None)]
#[command(version = VERSION)]
struct Args {
    /// Output header file (.h) instead of C source (.c)
    #[arg(short = 'H', long, default_value_t = false)]
    header: bool,

    /// Output 16-bit code points (char16_t) instead of 32-bit
    #[arg(short = 'S', long)]
    short_codes: Option<f32>,

    /// Output code point differences instead of absolute values
    #[arg(short = 'D', long, default_value_t = false)]
    differences: bool,

    /// Output code point ranges instead of individual code points
    #[arg(short = 'R', long, default_value_t = false)]
    ranges: bool,

    /// Output sparse array indexed by code point
    #[arg(long, default_value_t = false)]
    sparse: bool,

    /// Omit standard headers for Cosmopolitan compatibility
    #[arg(long, default_value_t = false)]
    cosmo: bool,

    /// Add hidden visibility attribute
    #[arg(long, default_value_t = false)]
    hidden: bool,

    /// Font name for C identifiers
    #[arg(short = 'N', long, default_value = "default")]
    font_name: String,

    /// Prefix for C identifiers
    #[arg(short = 'X', long, default_value = "")]
    prefix: String,

    /// Object file section name
    #[arg(long, default_value = "")]
    section: String,

    /// Extra comments to include in output
    #[arg(short = 'C', long, default_value = "")]
    comments: String,

    /// Include non-ASCII glyphs
    #[arg(long, default_value_t = true)]
    nonascii: bool,

    /// Include non-CP437 glyphs
    #[arg(long, default_value_t = true)]
    noncp437: bool,

    /// Include non-WGL4 glyphs
    #[arg(long, default_value_t = true)]
    nonwgl4: bool,

    /// Include Private Use Area glyphs
    #[arg(long, default_value_t = true)]
    pua: bool,

    /// Include supplementary plane glyphs
    #[arg(long, default_value_t = true)]
    supplementary: bool,

    /// Include Braille pattern glyphs
    #[arg(long, default_value_t = true)]
    braille: bool,

    /// Input BDF files
    #[arg(value_name = "FILE")]
    input_files: Vec<PathBuf>,
}

fn main() -> Result<()> {
    let args = Args::parse();

    if args.differences && args.ranges {
        return Err(anyhow!("cannot enable D and R options together"));
    }
    if (args.differences || args.ranges) && args.sparse {
        return Err(anyhow!("cannot enable D-or-R and SPARSE options together"));
    }

    let force_short = args.short_codes.map(|v| v >= 1.0).unwrap_or(false);
    let auto_short = args.short_codes.map(|v| v > 0.0 && v < 1.0).unwrap_or(false);

    let mut options = Options {
        output_header: args.header,
        force_short_codes: force_short,
        auto_short_codes: auto_short,
        use_differences: args.differences,
        use_ranges: args.ranges,
        sparse_array: args.sparse,
        cosmo: args.cosmo,
        hidden_visibility: args.hidden,
        font_name: args.font_name.clone(),
        identifier_prefix: args.prefix.clone(),
        section_name: args.section.clone(),
        extra_comments: args.comments.clone(),
        include_nonascii: args.nonascii,
        include_noncp437: args.noncp437,
        include_nonwgl4: args.nonwgl4,
        include_pua: args.pua,
        include_supplementary_planes: args.supplementary,
        include_braille: args.braille,
    };

    if options.force_short_codes {
        options.include_supplementary_planes = false;
    }

    let mut glyphs: BTreeMap<u32, Vec<u8>> = BTreeMap::new();
    let mut font_comments = String::new();

    if args.input_files.is_empty() {
        let mut input = String::new();
        io::stdin().read_to_string(&mut input)?;
        let (parsed_glyphs, comments) = BdfParser::parse(&input, &options)?;
        glyphs.extend(parsed_glyphs);
        font_comments.push_str(&comments);
    } else {
        for file_path in &args.input_files {
            let content = fs::read_to_string(file_path)?;
            let (parsed_glyphs, comments) = BdfParser::parse(&content, &options)?;
            glyphs.extend(parsed_glyphs);
            if !comments.is_empty() {
                if !font_comments.is_empty() {
                    font_comments.push('\n');
                }
                font_comments.push_str(&comments);
            }
        }
    }

    if glyphs.is_empty() {
        return Err(anyhow!("empty font"));
    }

    let mut generator = CodeGenerator::new(options, glyphs, font_comments)?;
    let output = generator.generate()?;
    println!("{}", output);

    Ok(())
}
