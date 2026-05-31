use crate::cp437_map::Cp437Map;
use crate::options::Options;
use anyhow::Result;
use std::collections::BTreeMap;

pub struct BdfParser;

#[derive(Debug, Clone)]
struct GlyphData {
    code_point: u32,
    width: u32,
    height: u32,
    bitmap: Vec<u8>,
}

impl BdfParser {
    pub fn parse(content: &str, options: &Options) -> Result<(BTreeMap<u32, Vec<u8>>, String)> {
        let cp437_map = if !options.include_noncp437 {
            Some(Cp437Map::new())
        } else {
            None
        };

        let mut glyphs = BTreeMap::new();
        let mut comments = String::new();
        let mut current_glyph: Option<GlyphData> = None;
        let mut in_bitmap = false;
        let mut bitmap_rows = Vec::new();

        for line in content.lines() {
            let trimmed = line.trim();

            if trimmed.starts_with("COMMENT")
                || trimmed.starts_with("COPYRIGHT")
                || trimmed.starts_with("HOMEPAGE")
                || trimmed.starts_with("NOTICE")
            {
                if trimmed.len() > 8 && trimmed.as_bytes()[7] == b' ' {
                    let comment_text = &trimmed[8..];
                    if !comments.is_empty() {
                        comments.push('\n');
                    }
                    comments.push_str(" * ");
                    comments.push_str(&sanitize_comment(comment_text));
                }
            }

            if trimmed.starts_with("ENCODING") {
                let parts: Vec<&str> = trimmed.split_whitespace().collect();
                if parts.len() >= 2 {
                    if let Ok(code) = parts[1].parse::<u32>() {
                        current_glyph = Some(GlyphData {
                            code_point: code,
                            width: 0,
                            height: 0,
                            bitmap: Vec::new(),
                        });
                    }
                }
                continue;
            }

            if trimmed.starts_with("BBX") {
                if let Some(glyph) = &mut current_glyph {
                    let parts: Vec<&str> = trimmed.split_whitespace().collect();
                    if parts.len() >= 3 {
                        if let (Ok(w), Ok(h)) = (parts[1].parse::<u32>(), parts[2].parse::<u32>()) {
                            glyph.width = w;
                            glyph.height = h;
                        }
                    }
                }
                continue;
            }

            if trimmed == "BITMAP" {
                in_bitmap = true;
                bitmap_rows.clear();
                continue;
            }

            if in_bitmap && !trimmed.is_empty() && !trimmed.starts_with("ENDCHAR") {
                if is_hex_line(trimmed) {
                    bitmap_rows.push(trimmed.to_string());
                }
                continue;
            }

            if trimmed == "ENDCHAR" {
                in_bitmap = false;
                if let Some(mut glyph) = current_glyph.take() {
                    if should_include_glyph(glyph.code_point, options, cp437_map.as_ref()) {
                        if !bitmap_rows.is_empty() {
                            glyph.bitmap = bitmap_rows_to_bytes(&bitmap_rows, glyph.width);
                            glyphs.insert(glyph.code_point, glyph.bitmap);
                        }
                    }
                }
                bitmap_rows.clear();
                current_glyph = None;
                continue;
            }

            if trimmed == "ENDFONT" {
                break;
            }
        }

        Ok((glyphs, comments))
    }
}

fn is_hex_line(s: &str) -> bool {
    s.chars().all(|c| c.is_ascii_hexdigit() || c.is_whitespace())
}

fn bitmap_rows_to_bytes(rows: &[String], width: u32) -> Vec<u8> {
    let width_bytes = ((width + 7) / 8) as usize;
    let mut bitmap = Vec::new();

    for row in rows {
        let hex_str = row.trim();
        for i in (0..hex_str.len()).step_by(2) {
            if i + 1 < hex_str.len() {
                if let Ok(byte) = u8::from_str_radix(&hex_str[i..i + 2], 16) {
                    bitmap.push(byte);
                }
            }
        }
    }

    bitmap
}

fn should_include_glyph(code: u32, options: &Options, cp437_map: Option<&Cp437Map>) -> bool {
    if !options.include_nonascii && (code < 0x20 || code > 0x7F) {
        return false;
    }

    if let Some(map) = cp437_map {
        if !map.contains(code) {
            return false;
        }
    }

    if !options.include_nonwgl4 {
        let in_wgl4 = (code >= 0x0020 && code <= 0x01FF)
            || (code >= 0x02C0 && code <= 0x02DF)
            || (code >= 0x0380 && code <= 0x03CF)
            || (code >= 0x0400 && code <= 0x049F)
            || (code >= 0x1E80 && code <= 0x266F)
            || (code >= 0xF001 && code <= 0xF002)
            || (code >= 0xFB01 && code <= 0xFB02);

        if !in_wgl4 {
            return false;
        }
    }

    if !options.include_supplementary_planes && code > 0xFFFF {
        return false;
    }

    if !options.include_pua {
        if (code >= 0xE000 && code <= 0xF8FF)
            || (code >= 0xF0000 && code <= 0xFFFD)
            || (code >= 0x100000 && code <= 0x10FFFD)
        {
            return false;
        }
    }

    if !options.include_braille && code >= 0x2800 && code <= 0x28FF {
        return false;
    }

    true
}

fn sanitize_comment(s: &str) -> String {
    s.replace("\\*/", "\\*\\/")
        .replace("/*", "/\\*")
        .replace("*/", "*\\/")
}
