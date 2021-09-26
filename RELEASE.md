# What to do for a release?

```
perl Makefile.PL
make check
make test
```

Update `Changes` with user-visible changes.

Check the copyright year in the `LICENSE`.

Double check the `MANIFEST`. Did we add new files that should be in
here?

```
perl Makefile.PL
make manifest
```

Increase the version in `lib/Game/FaceGenerator.pm`.

Commit any changes and tag the release.

Prepare an upload by using n.nn_nn for a developer release:

```
perl Makefile.PL
make distdir
mv Game-FaceGenerator-1.01 Game-FaceGenerator-1.01_01
tar czf Game-FaceGenerator-1.01_01.tar.gz Game-FaceGenerator-1.01_01
trash Game-FaceGenerator-1.01_01
cpan-upload -u SCHROEDER Game-FaceGenerator-1.01_01.tar.gz
```

If you’re happy with the results:

```
perl Makefile.PL && make && make dist
cpan-upload -u SCHROEDER Game-FaceGenerator-1.02.tar.gz
```
