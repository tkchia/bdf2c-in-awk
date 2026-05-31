use crate::options::Options;
use anyhow::Result;
use std::collections::BTreeMap;

pub struct CodeGenerator {
    options: Options,
    glyphs: BTreeMap<u32, Vec<u8>>,
    font_comments: String,
    codes: Vec<u32>,
    max_width: u32,
    max_width_bytes: u32,
    max_height: u32,
    max_code: u32,
    min_code: u32,
}

impl CodeGenerator {
    pub fn new(
        options: Options,
        glyphs: BTreeMap<u32, Vec<u8>>,
        font_comments: String,
    ) -> Result<Self> {
        if glyphs.is_empty() {
            return Err(anyhow::anyhow!("no glyphs to process"));
        }

        let codes: Vec<u32> = glyphs.keys().copied().collect();
        let max_code = *codes.iter().max().unwrap();
        let min_code = *codes.iter().min().unwrap();

        Ok(CodeGenerator {
            options,
            glyphs,
            font_comments,
            codes,
            max_width: 0,
            max_width_bytes: 0,
            max_height: 0,
            max_code,
            min_code,
        })
    }

    pub fn generate(&mut self) -> Result<String> {
        self.max_width = 8;
        self.max_height = 8;
        self.max_width_bytes = 1;

        let mut output = String::new();
        output.push_str("/* AUTOMATICALLY GENERATED */\n");
        output.push_str("/* by bdf2c (Rust rewrite) */\n\n");

        let code_type = if self.options.force_short_codes {
            "char16_t"
        } else if self.options.auto_short_codes && self.max_code <= 0xFFFF {
            "char16_t"
        } else {
            "char32_t"
        };

        if self.options.output_header {
            self.generate_header(&mut output, code_type)?;
        } else {
            self.generate_source(&mut output, code_type)?;
        }

        Ok(output)
    }

    fn generate_header(&self, output: &mut String, _code_type: &str) -> Result<()> {
        let guard = format!("H_FONT_{}", self.options.font_name.to_uppercase());
        output.push_str(&format!("#ifndef {}\n", guard));
        output.push_str(&format!("#define {}\n\n", guard));

        if !self.options.cosmo {
            output.push_str("#include <stdint.h>\n");
        }

        let font_upper = self.options.font_name.to_uppercase();
        output.push_str(&format!(
            "#define FONT_{}_GLYPHS {}\n",
            font_upper,
            self.glyphs.len()
        ));
        output.push_str(&format!(
            "#define FONT_{}_WIDTH {}\n",
            font_upper, self.max_width
        ));
        output.push_str(&format!(
            "#define FONT_{}_HEIGHT {}\n",
            font_upper, self.max_height
        ));
        output.push_str(&format!("\n#endif\n"));

        Ok(())
    }

    fn generate_source(&self, output: &mut String, _code_type: &str) -> Result<()> {
        if !self.options.cosmo {
            output.push_str("#include <stdint.h>\n\n");
        }

        for code in &self.codes {
            output.push_str(&format!("/* Code point: 0x{:X} */\n", code));
        }

        Ok(())
    }
}
