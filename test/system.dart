import "package:builder/system.dart";
import 'package:unittest/unittest.dart';
import 'dart:io';
import 'dart:async';

// These are fixed paths used between the different testing methods. The
// testing methods have been split into separate functions, but to avoid using
// other calls in a ls test, the ls test depends on the mkdir test. Hence the
// shared variables and the use of completers.
String dir           = '/tmp/dart-builder-test';
String dir2          = '/tmp/dart-builder-test/cp';
String dir3          = '/tmp/dart-builder-test/cp-2';
String dir_deep      = '/tmp/dart-builder-test/one/two/three';
String dir_deep_root = '/tmp/dart-builder-test/one';

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
  Future mkdirTest, mkdirDeepTest;

  mkdirTest     = mkdir(dir);
  mkdirDeepTest = mkdir(dir_deep);

  test( 'mkdir', () =>
      mkdirTest
        .then((dir) => exists_test(dir, true))
    );
  test( 'mkdir-deep', () =>
      mkdirDeepTest
        .then((dir) => exists_test(dir, true))
    );

  return Future.wait([mkdirTest, mkdirDeepTest]);
}

make_test_files () =>
  Future.wait([file, file2].map((f) => new File(f).create()));

test_link () {
  Future lnFileTest, lnDirectoryTest, lnLinkTest;

  lnFileTest      = ln(file, link);
  lnDirectoryTest = ln(dir, link2);
  lnLinkTest      = lnFileTest.then((_) => ln(link, link3));

  test( 'ln-file', () =>
      lnFileTest
        .then((link) => exists_test(dir, true))
    );
  test( 'ln-directory', () =>
      lnDirectoryTest
        .then((link) => exists_test(dir, true))
    );
  test( 'ln-file', () =>
      lnLinkTest
        .then((link) => exists_test(dir, true))
    );

  return Future.wait([lnFileTest, lnDirectoryTest, lnLinkTest]);
}

test_cp () {
  Future cpFileTest, cpDirectoryTest, cpDirectoryDeepTest, cpLinkTest;

  cpFileTest          = cp(file, file3);
  cpDirectoryTest     = cp(dir_deep, dir2);
  cpDirectoryDeepTest = cp(dir, dir3);
  cpLinkTest          = cp(link, link4);

  test( 'cp-file', () =>
    cpFileTest
      .then((file) => exists_test(file, true))
  );
  test( 'cp-directory', () =>
    cpDirectoryTest
      .then((file) => exists_test(file, true))
  );
  test( 'cp-directory-deep', () =>
    cpDirectoryDeepTest
      .then((file) => exists_test(file, true))
  );
  test( 'cp-link', () =>
    cpLinkTest
      .then((file) => exists_test(file, true))
  );

  return Future.wait([cpFileTest, cpDirectoryTest, cpDirectoryDeepTest, cpLinkTest]);
}

test_ls () {
  Future lsFileTest, lsDirectoryTest, lsLinkTest;

  lsFileTest      = ls(file);
  lsDirectoryTest = ls(dir);
  lsLinkTest      = ls(link);

  test( 'ls-file', () =>
    lsFileTest
      .then((Stream stream) => stream.toList())
      .then((List<String> files) => expect(files, equals([file])))
  );
  test( 'ls-directory', () =>
    lsDirectoryTest
      .then((Stream stream) => stream.toList())
      .then((List<String> files) {
        List<String> expected = [dir2, dir3, dir_deep_root, file, file2, file3, link, link2, link3, link4];
        files.sort();
        expected.sort();
        return expect(files, equals(expected));
      })
  );
  test( 'ls-link', () =>
    lsLinkTest
      .then((Stream stream) => stream.toList())
      .then((List<String> files) => expect(files, equals([link])))
  );

  return Future.wait([lsFileTest, lsDirectoryTest, lsLinkTest]);
}

test_rm () {
  Future rmFileTest, rmDirectoryTest, rmDirectoryDeepTest, rmLinkTest;

  rmFileTest          = rm(file);
  rmDirectoryTest     = rm(dir_deep);
  rmLinkTest          = rm(link);
  rmDirectoryDeepTest = Future.wait([rmFileTest, rmDirectoryTest, rmLinkTest]).then((_) => rm(dir));

  test( 'rm-file', () =>
    rmFileTest
      .then((file) => exists_test(file, false))
  );
  test( 'rm-directory', () =>
    rmDirectoryTest
      .then((file) => exists_test(file, false))
  );
  test( 'rm-link', () =>
    rmLinkTest
      .then((file) => exists_test(file, false))
  );
  test( 'rm-directory-deep', () =>
    rmDirectoryDeepTest
      .then((file) => exists_test(file, false))
  );

  return Future.wait([rmFileTest, rmDirectoryTest, rmDirectoryDeepTest, rmLinkTest]);
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
