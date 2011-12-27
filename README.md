Homebrew
========
Features, usage and installation instructions are [summarized on the homepage][home].

Fork's TODO-List:
----------------
1.  *Make homebrew modular*;
  *   **(done)** *Extract formulas to own repository*. This idea was declined a couple of
      times [mxcl/homebrew#3991](https://github.com/mxcl/homebrew/issues/3991),
      [mxcl/homebrew#236](https://github.com/mxcl/homebrew/issues/9018). Keeping formulas
      in the core makes homebrew a little bit harder to maintain and contribute;
  *   **(done)** *`homebrew selfupdate` command*; After extracting formulas to own
      repository will be easy to update them and core separately.
  *   *Split-up core and cmd app*. Library should provide
      an API that could be used by other application (GUI, for example);
  *   **(done)** *Extract 'Contributions' to 'homebrew-contrib' repo*.
      'Contributions' is now available through the `brew install homebrew-contrib`;
2. *3rd party formulas repos support* (?);
3. *GUI application*; (?)
4. *MacRuby support*; (?)
5. *Improve installer*; (?)
6. *Extensions engine*; (?)
7. *Improve tests*;
8. *Use rugged (or another ruby-git library)*;
9. *Improve core documentation*;

What Packages Are Available?
----------------------------
1. You can [browse the Formula folder on GitHub][formula].
2. Or type `brew search` for a list.

More Documentation
------------------
`brew help` or `man brew` or check our [wiki][].

Who Are You?
------------
I'm [Max Howell][mxcl] and I'm a splendid chap.


[home]:http://mxcl.github.com/homebrew
[wiki]:http://wiki.github.com/mxcl/homebrew
[mxcl]:http://twitter.com/mxcl
[formula]:http://github.com/mxcl/homebrew/tree/master/Library/Formula/
