/// Configuration options for BDF to C conversion
#[derive(Debug, Clone)]
pub struct Options {
    pub output_header: bool,
    pub force_short_codes: bool,
    pub auto_short_codes: bool,
    pub use_differences: bool,
    pub use_ranges: bool,
    pub sparse_array: bool,
    pub cosmo: bool,
    pub hidden_visibility: bool,
    pub font_name: String,
    pub identifier_prefix: String,
    pub section_name: String,
    pub extra_comments: String,
    pub include_nonascii: bool,
    pub include_noncp437: bool,
    pub include_nonwgl4: bool,
    pub include_pua: bool,
    pub include_supplementary_planes: bool,
    pub include_braille: bool,
}
