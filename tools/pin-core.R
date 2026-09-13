# Shared helpers for the tools that read ferx-core at the pinned revision.
#
# Every tool reads ferx-core with `git show <ferx_core_sha>:<path>`, never from
# a working tree. Two things can go wrong, and both used to be quiet enough to
# poison a generated file:
#
#   * there is no checkout at `core_dir`. Inside a git worktree the default
#     sibling path resolves to <repo>/.claude/worktrees/ferx-core, which does
#     not exist, so every `git show` failed while the tool kept going;
#   * the checkout exists but has never fetched the pinned revision.
#
# tools/settings-docs.R hit the first case and wrote tools/settings-docs.csv
# with all 95 ferx-core descriptions blank; tools/audit.R then reported
# "AUDIT OK" against a features.csv the failed inventory had never rewritten.
# Hence: resolve once, fail loudly, and never half-write a tracked file.

# Check that `core_dir` is a git checkout that has `sha`. Returns the resolved
# path; stops with the fix when it is not usable.
require_ferx_core <- function(core_dir, sha) {
  recipe <- paste0(
    "ferx-core checkout not usable at '", core_dir, "'.\n",
    "  The tools read ferx-core at the pinned revision with `git show`.\n",
    "  From a git worktree the default sibling path does not exist. Link it once:\n",
    "    ln -s ../../../ferx-core <book>/.claude/worktrees/ferx-core\n",
    "  or pass the path: Rscript tools/<tool>.R /path/to/ferx-core"
  )
  if (!dir.exists(core_dir)) stop(recipe, call. = FALSE)
  is_repo <- system2("git", c("-C", core_dir, "rev-parse", "--git-dir"),
                     stdout = FALSE, stderr = FALSE)
  if (!identical(is_repo, 0L)) stop(recipe, call. = FALSE)
  has_rev <- system2("git", c("-C", core_dir, "cat-file", "-e", paste0(sha, "^{commit}")),
                     stdout = FALSE, stderr = FALSE)
  if (!identical(has_rev, 0L)) {
    stop("ferx-core at '", core_dir, "' does not have the pinned revision ", sha, ".\n",
         "  Fetch it: git -C ", core_dir, " fetch origin", call. = FALSE)
  }
  invisible(normalizePath(core_dir))
}

# `git show <sha>:<path>`, fatal on any failure, including a path that does not
# exist at that revision.
git_show_at <- function(core_dir, sha, path) {
  out <- system2("git", c("-C", core_dir, "show", paste0(sha, ":", path)),
                 stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop("git show ", sha, ":", path, " failed in '", core_dir, "':\n  ",
         paste(out, collapse = "\n  "), call. = FALSE)
  }
  out
}

# Replace `path` only once the whole table exists: write a temporary file in the
# same directory, then rename. An aborted run leaves the tracked file untouched.
write_csv_atomic <- function(x, path) {
  tmp <- tempfile(pattern = paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(tmp), add = TRUE)
  utils::write.csv(x, tmp, row.names = FALSE)
  if (!file.rename(tmp, path)) stop("could not replace ", path, call. = FALSE)
  invisible(path)
}

# Record the pin a generated file was built at, so tools/audit.R can refuse to
# grade a features.csv that predates the current pin.
write_pin_stamp <- function(pin, path = "tools/features-pin.yml") {
  writeLines(c(
    "# Written by tools/inventory.R: the pin tools/features.csv was generated at.",
    "# tools/audit.R fails when this does not match _variables.yml.",
    paste0("ferx_r_sha: ", pin$ferx_r_sha),
    paste0("ferx_core_sha: ", pin$ferx_core_sha),
    paste0("ferx_version: ", as.character(utils::packageVersion("ferx"))),
    paste0("generated: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
  ), path)
  invisible(path)
}
