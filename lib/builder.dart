library builder;
import 'dart:async';

/*
   The build operation class defines the generic process of building code. This
   is a simple case of executing each stage in order to completion. Specific
   operations can require that another operation reaches a specific stage.

   The following stages have been defined:

   * clean (optional)
     Clean operations cannot depend on others. All clean operations are
     executed at the same time at the start of the build process.

   * preprocess
     Prepare code for compilation.

   * compile
     Compile code.

   * postprocess
     Clean compilation artifacts not required for packaging or execution.

   * package
     Bundle the code for distribution.

   To implement the appropriate stages, subclass this and define those methods.
   Those methods will be turned into futures which can be accessed with
   do_STAGE. This will always return the same future for the same class
   implementation, so dependencies on the execution of them can be consistently
   applied. To make this easier, the require_STAGE method takes futures that
   must complete before the indicated stage can start.

   All of this is just configuration until the static run method is called with
   the complete list of build operations to execute. Once that has been done
   the class will be locked and further attempts to configure it will throw an
   exception.
*/
_defaultOperation (x) => true;
class BuildOperation {
  var clean, preprocess, compile, postprocess, package;

  BuildOperation ({
    var clean:       _defaultOperation,
    var preprocess:  _defaultOperation,
    var compile:     _defaultOperation,
    var postprocess: _defaultOperation,
    var package:     _defaultOperation
  }) {
    this.clean       = new BuildStage(clean);
    this.preprocess  = new BuildStage(preprocess);
    this.compile     = new BuildStage(compile);
    this.postprocess = new BuildStage(postprocess);
    this.package     = new BuildStage(package);
  }

  BuildStage do_clean       () => this.clean;
  BuildStage do_preprocess  () => this.preprocess;
  BuildStage do_compile     () => this.compile;
  BuildStage do_postprocess () => this.postprocess;
  BuildStage do_package     () => this.package;

  void require_clean       (BuildStage requirement) { this.clean.require(requirement); }
  void require_preprocess  (BuildStage requirement) { this.preprocess.require(requirement); }
  void require_compile     (BuildStage requirement) { this.compile.require(requirement); }
  void require_postprocess (BuildStage requirement) { this.postprocess.require(requirement); }
  void require_package     (BuildStage requirement) { this.package.require(requirement); }

  static Future run (List<BuildOperation> operations, { bool clean: false, bool package: false }) {
    Future build;

    build = clean
          ? Future.wait(new List.from(operations.map((o) => o.clean.make())))
          : new Future.value([]);
    return build.then((_) => Future.wait(new List.from(operations.map((o) => o._run(package: package)))));
  }
  Future _run ({ bool package: true }) {
    Future build = this.preprocess.make()
      .then((_) => this.compile.make())
      .then((_) => this.postprocess.make());

    if ( package ) {
      return build.then((_) => this.package.make());
    }
    return build;
  }
}

/*
   A single component of the build operation.
*/
class BuildStage {
  List<Future> _requirements = new List();
  Completer _completer = new Completer();
  Future _make;
  var _action;

  BuildStage(action) {
    this._action = action;
  }

  void require (BuildStage stage) {
    if ( _make == null ) {
      _requirements.add(stage._completer.future);
    }
    else {
      throw new Exception('Build Stage already made');
    }
  }
  Future make () {
    if ( _make == null ) {
      _make = Future.wait(_requirements)
        .then((List requirements) => this._action(requirements))
        .then((result) => this._completer.complete(result));
    }
    return _make;
  }
}
