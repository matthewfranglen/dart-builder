import "package:builder/system.dart";
import 'package:unittest/unittest.dart';
import 'dart:io';
import 'dart:async';

// These are fixed paths used between the different testing methods. The
// testing methods have been split into separate functions, but to avoid using
// other calls in a ls test, the ls test depends on the mkdir test. Hence the
// shared variables and the use of completers.
String dir      = '/tmp/dart-builder-test';
String cp_dir   = '/tmp/dart-builder-test/cp';
String cp_dir2  = '/tmp/dart-builder-test/cp-2';
String deep_dir = '/tmp/dart-builder-test/one/two/three';

String file  = '${dir}/file';
String file2 = '${dir}/file-2';
String file3 = '${dir}/file-3';

String link  = '${dir}/link';
String link2 = '${dir}/link-2';
String link3 = '${dir}/link-3';
String link4 = '${dir}/link-4';

// This tests if there is a file of any type at the specified path.
Future exists_test(String path, bool should) =>
      FileSystemEntity.type(path)
        .then((FileSystemEntityType type) => type != FileSystemEntityType.NOT_FOUND)
        .then((bool exists) => expect(exists, equals(should)));

test_mkdir () {
  Completer mkdirTest, mkdirDeepTest;

  mkdirTest     = new Completer();
  mkdirDeepTest = new Completer();

  test( 'mkdir', () =>
      mkdir(dir)
        .then((dir) => exists_test(dir, true))
        .then((_)   => mkdirTest.complete(true))
    );
  test( 'mkdir-deep', () =>
      mkdir(deep_dir)
        .then((dir) => exists_test(dir, true))
        .then((_)   => mkdirDeepTest.complete(true))
    );

  return Future.wait([mkdirTest.future, mkdirDeepTest.future]);
}

make_test_files () =>
  Future.wait([file, file2].map((f) => new File(f).create()));

test_link () {
  Completer lnFileTest, lnDirectoryTest, lnLinkTest;

  lnFileTest      = new Completer();
  lnDirectoryTest = new Completer();
  lnLinkTest      = new Completer();

  test( 'ln-file', () =>
      ln(file, link)
        .then((link) => exists_test(dir, true))
        .then((_)    => lnFileTest.complete(true))
    );
  test( 'ln-directory', () =>
      ln(dir, link2)
        .then((link) => exists_test(dir, true))
        .then((_)    => lnDirectoryTest.complete(true))
    );
  test( 'ln-file', () =>
      ln(link, link3)
        .then((link) => exists_test(dir, true))
        .then((_)    => lnLinkTest.complete(true))
    );

  return Future.wait([lnFileTest.future, lnDirectoryTest.future, lnLinkTest.future]);
}

test_cp () {
  Completer cpFileTest, cpDirectoryTest, cpDirectoryDeepTest, cpLinkTest;

  cpFileTest          = new Completer();
  cpDirectoryTest     = new Completer();
  cpDirectoryDeepTest = new Completer();
  cpLinkTest          = new Completer();

  test( 'cp-file', () =>
    cp(file, file3)
      .then((file) => exists_test(file, true))
      .then((_)    => cpFileTest.complete(true))
  );
  test( 'cp-directory', () =>
    // deep dir is the dir within lots of directories
    cp(deep_dir, cp_dir)
      .then((file) => exists_test(file, true))
      .then((_)    => cpDirectoryTest.complete(true))
  );
  test( 'cp-directory-deep', () =>
    // dir contains deep dir and all the other things
    cp(dir, cp_dir2)
      .then((file) => exists_test(file, true))
      .then((_)    => cpDirectoryDeepTest.complete(true))
  );
  test( 'cp-link', () =>
    cp(link, link4)
      .then((file) => exists_test(file, true))
      .then((_)    => cpLinkTest.complete(true))
  );

  return Future.wait([cpFileTest.future, cpDirectoryTest.future, cpDirectoryDeepTest.future, cpLinkTest.future]);
}

test_ls () {
  Completer lsFileTest, lsDirectoryTest, lsLinkTest;

  lsFileTest      = new Completer();
  lsDirectoryTest = new Completer();
  lsLinkTest      = new Completer();

  test( 'ls-file', () =>
    ls(file)
      .then((f) => expect(f, equals(file)))
      .then((_) => lsFileTest.complete(true))
  );
  test( 'ls-directory', () =>
    ls(dir)
      .then((d) => expect(d, equals(dir)))
      .then((_) => lsDirectoryTest.complete(true))
  );
  test( 'ls-link', () =>
    ls(link)
      .then((f) => expect(f, equals(link)))
      .then((_) => lsLinkTest.complete(true))
  );

  return Future.wait([lsFileTest.future, lsDirectoryTest.future, lsLinkTest.future]);
}

test_rm () {
  Completer rmFileTest, rmDirectoryTest, rmDirectoryDeepTest, rmLinkTest;

  rmFileTest          = new Completer();
  rmDirectoryTest     = new Completer();
  rmDirectoryDeepTest = new Completer();
  rmLinkTest          = new Completer();

  test( 'rm-file', () =>
    rm(file)
      .then((file) => exists_test(file, false))
      .then((_)    => rmFileTest.complete(true))
  );
  test( 'rm-directory', () =>
    rm(file)
      .then((file) => exists_test(file, false))
      .then((_)    => rmDirectoryTest.complete(true))
  );
  test( 'rm-link', () =>
    rm(file)
      .then((file) => exists_test(file, false))
      .then((_)    => rmLinkTest.complete(true))
  );
  test( 'rm-directory-deep', () =>
    rm(file)
      .then((file) => exists_test(file, false))
      .then((_)    => rmDirectoryDeepTest.complete(true))
  );

  return Future.wait([rmFileTest.future, rmDirectoryTest.future, rmDirectoryDeepTest.future, rmLinkTest.future]);
}

main () {
  Future do_group(name, function) {
    Completer result = new Completer();
    group(name, () => function().then((_) => result.complete(true)));
    return result.future;
  }

  do_group('mkdir', test_mkdir)
    .then((_) => make_test_files())
    .then((_) => Future.wait([do_group('cp', test_cp), do_group('ln', test_link)]))
    .then((_) => do_group('ls', test_ls))
    .then((_) => do_group('rm', test_rm));
}
