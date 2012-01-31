## 0.9.0 (Unreleased) ##

*  Replaced HOMEBREW_*, MACOS_* constants with corresponding modules
   (ex. `Homebrew.version`)
*  Refactored checksum methods. Added `Pathname::Checksum` module with
   spec:
      * `Pathname#sha2` -> `Pathname#sha256`
*  `StringInreplaceExtension` renamed to `MakefileInreplace`, moved to
   `utils.rb`, new syntax introduced:
      * `change_make_var!` -> `change_var!`
      * `remove_make_var!` -> `remove_var!`
      * `get_make_var`    -> `get_var`
   Added deprecation notices

*  Added some rspec tests

*  Converted `Hardware` class to Module

*  Moved `*DownloadStrategy` classes to own module, for example:
   `AbstractDownloadStrategy` was replaced with
   `DownloadStrategy::Abstract` class. Deprecation notice was added.
   for example: `AbstractDownloadStrategy` replaced

*  `contrib` was extracted to `homebrew-contrib` formula

*  `brew update` command updates only formulas

*  New `brew selfupdate` command which updates code

*  Formulas were extracted to own repository

*  `OkJson` patched to accept symbols

*  `MultiJson` replaced with `OkJson` (vendored `MultiJson` was hardwired to
   it anyway)
