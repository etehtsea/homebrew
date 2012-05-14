## 0.9.0 (Unreleased) ##

*  Made project structure more usual

*  Moved `Formulary` to `/usr/local/formulary`

*  Experimental 3rd party repositories support with following commands:
      * `brew formulary init` - pull main repository
      * `brew formulary add/remove/list` - add/remove/list repos

*  Centralized `Doctor` checks and introduced `Doctor.preinstall_checks` and `Doctor.runtime_checks`

*  Added possibility to experinent with ENV flags, such as `CC`, `CXX`, `CFLAGS`, `CXXFLAGS`, `MAKEFLAGS`, so
   now brew respects user choice. For example: `MAKEFLAGS=-j5 CC=gcc-4.7 brew install <smth>`
   Moreover, you `homebrew` doesn't directly depend on `Xcode`, you should simply have your compiler in the path
   (warning: no guarantee that formula won't fail)

*  Fixed ccache support
  
*  Splitted `Utils` to [modules](https://github.com/etehtsea/homebrew/tree/master/Library/Homebrew/utils).

*  Refactored `update` mechanism. Introduced two new commands:
      * `brew selfupdate` which updates homebrew core
      * `brew repoupdate` which updates formulary
      * `brew update` still updates both

*  Git related stuff extracted in its own file

*  Removed *compatibility/* layer

*  MacOS module extracted in its own file

*  Replaced HOMEBREW_*, MACOS_* constants with corresponding modules
   (ex. `Homebrew.version`, `MacOS.lion?`)

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

*  Formulas were extracted in their own repository

*  `OkJson` patched to accept symbols

*  `MultiJson` replaced with `OkJson` (vendored `MultiJson` was hardwired to
   it anyway)
