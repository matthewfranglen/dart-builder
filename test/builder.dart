import "package:builder.dart";
import 'package:unittest/unittest.dart';

BuildOperation make_op (List result, {String name: ''}) {
  var log = (x) {
    result.add(x);
  };
  return new BuildOperation(
    clean:       (_) => log('${name}clean'),
    preprocess:  (_) => log('${name}preprocess'),
    compile:     (_) => log('${name}compile'),
    postprocess: (_) => log('${name}postprocess'),
    package:     (_) => log('${name}package')
  );
}

test_stage_order () {
  test( 'Default', () {
    List result = new List();

    expect(result, equals([]));
    BuildOperation.run([make_op(result)]).then(expectAsync1((_) {
      expect(result, equals(['preprocess', 'compile', 'postprocess']));
    }));
  });

  test( 'Clean', () {
    List result = new List();

    expect(result, equals([]));
    BuildOperation.run([make_op(result)], clean: true).then(expectAsync1((_) {
      expect(result, equals(['clean', 'preprocess', 'compile', 'postprocess']));
    }));
  });

  test( 'Package', () {
    List result = new List();

    expect(result, equals([]));
    BuildOperation.run([make_op(result)], package: true).then(expectAsync1((_) {
      expect(result, equals(['preprocess', 'compile', 'postprocess', 'package']));
    }));
  });

  test( 'Clean Package', () {
    List result = new List();

    expect(result, equals([]));
    BuildOperation.run([make_op(result)], clean: true, package: true).then(expectAsync1((_) {
      expect(result, equals(['clean', 'preprocess', 'compile', 'postprocess', 'package']));
    }));
  });
}

test_stage_dependency () {
  test( 'Default', () {
    List result = new List();
    BuildOperation one, two;

    one = make_op(result, name: 'one-');
    two = make_op(result, name: 'two-');

    two.require_preprocess(one.do_preprocess());

    one.require_compile(two.do_preprocess());
    two.require_compile(one.do_compile());

    one.require_postprocess(two.do_compile());
    two.require_postprocess(one.do_postprocess());

    one.require_package(two.do_postprocess());
    two.require_package(one.do_package());

    expect(result, equals([]));
    BuildOperation.run([one, two], package: true).then(expectAsync1((_) {
      expect(result, equals(['one-preprocess', 'two-preprocess', 'one-compile', 'two-compile', 'one-postprocess', 'two-postprocess', 'one-package', 'two-package']));
    }));
  });
}

test_multi_operation () {
  test( '15', () {
    List result = new List();

    expect(result, equals([]));
    BuildOperation.run([make_op(result), make_op(result), make_op(result), make_op(result), make_op(result)]).then(expectAsync1((_) {
      expect(result.length, equals(15));
    }));
  });
  test( '75', () {
    List result = new List();

    expect(result, equals([]));
    BuildOperation.run([
        make_op(result), make_op(result), make_op(result), make_op(result), make_op(result),
        make_op(result), make_op(result), make_op(result), make_op(result), make_op(result),
        make_op(result), make_op(result), make_op(result), make_op(result), make_op(result),
        make_op(result), make_op(result), make_op(result), make_op(result), make_op(result),
        make_op(result), make_op(result), make_op(result), make_op(result), make_op(result),
      ]).then(expectAsync1((_) {
      expect(result.length, equals(75));
    }));
  });
}

main () {
  group( 'Stage Order', test_stage_order );
  group( 'Stage Dependency', test_stage_dependency );
  group( 'Multi Operation', test_multi_operation );
}
