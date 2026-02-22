use std::path::PathBuf;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Direction {
    ToHome,
    ToRepo,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Status {
    Same,
    Different,
    MissingSource,
    MissingDest,
    SymlinkOk,
    SymlinkWrong,
    SymlinkMissing,
    Conflict(String),
}

#[derive(Debug, Clone)]
pub struct FileRecord {
    pub rel_path: PathBuf,
    pub src_path: PathBuf,
    pub dest_path: PathBuf,
    pub status: Status,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncMode {
    Copy,
    Symlink,
}
