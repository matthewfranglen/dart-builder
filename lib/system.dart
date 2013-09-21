library system;
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

/*
   Copies a file or directory to a new location.
*/
Future<String> cp(String source, String dest) {
  var copy_directory, copy_file, copy_link;

  copy_directory = (String source, String dest) =>
      mkdir(dest)
        .then((_) => ls(source))
        .then((Stream content) => content.pipe(new _CopyConsumer(source, dest)));

  // Future.wait returns a list which is in the same order as the list passed to Future.wait
  copy_file = (String source, String dest) => new File(dest).openWrite().addStream(new File(source).openRead());

  copy_link = (String source, String dest) =>
      new Future.value(new Link(source))
        .then((Link source)   => source.isAbsolute ? source.target() : source.absolute.target())
        .then((String target) => new Link(dest).create(target));


  // Future.wait returns a list which is in the same order as the list passed to Future.wait
  return Future.wait([
      FileSystemEntity.type(source),
      FileSystemEntity.type(dest)
    ]).then((types) {
      if (types[1] == FileSystemEntityType.NOT_FOUND) {
        switch (types[0]) {
          case FileSystemEntityType.DIRECTORY: return copy_directory(source, dest);
          case FileSystemEntityType.FILE:      return copy_file(source, dest);
          case FileSystemEntityType.LINK:      return copy_link(source, dest);
        }
      } else {
        // Not going to replace existing things.
        // TODO Complete with error?
        return dest;
      }
    });
}

/*
   Receives the results of the directory listing and passes them to cp.
*/
class _CopyConsumer<String> implements StreamConsumer {
  final Completer _completer = new Completer();
  final String _source, _destination;

  _CopyConsumer(this._source, this._destination);

  Future addStream(Stream stream) {
    stream.listen(
        (String file) => cp(path.join(_source, file), path.join(_destination, file)),
        onDone: ()    => _completer.complete(this)
      );

    return _completer.future;
  }

  Future close() {
    if (!_completer.isCompleted) {
      _completer.complete(this);
    }
    return _completer.future;
  }
}

/*
   Creates a symlink to target at link.
*/
Future<String> ln(String target, String link) {
  return FileSystemEntity.type(link)
    .then((FileSystemEntityType type) => type == FileSystemEntityType.NOT_FOUND
                                       ? new Link(link).create(target).then((Link l) => l.path)
                                       : link
    );
}

/*
   Lists the directory at path.
*/
Future<Stream<String>> ls(String target) {
  return FileSystemEntity.type(target)
    .then((FileSystemEntityType type) {
      if (type == FileSystemEntityType.DIRECTORY) {
        return new Directory(target).list().map((FileSystemEntity entity) => entity.path);
      }

      final StreamController controller = new StreamController<String>();

      // If the path exists, then add it, as it would get listed by the regular ls
      if (type != FileSystemEntityType.NOT_FOUND) {
        controller.add(target);
      }
      controller.close();

      return controller.stream;
    });
}

/*
   Creates a directory at the path.
*/
Future<String> mkdir(String path) {
  return FileSystemEntity.type(path)
    .then((FileSystemEntityType type) => type == FileSystemEntityType.NOT_FOUND
                                       ? new Directory(path).create(recursive: true).then((Directory dir) => dir.path)
                                       : path
    );
}

/*
   Moves a file or directory to a new location.
*/
Future<String> mv(String source, String dest) {
  return FileSystemEntity.type(source)
    .then((FileSystemEntityType type) {
      switch(type) {
        case FileSystemEntityType.FILE:
          return new File(source).rename(dest).then((FileSystemEntity entity) => entity.path);
        case FileSystemEntityType.DIRECTORY:
          return new Directory(source).rename(dest).then((FileSystemEntity entity) => entity.path);
        case FileSystemEntityType.LINK:
          return new Link(source).rename(dest).then((FileSystemEntity entity) => entity.path);
      }
      return dest;
    });
}

/*
   Deletes files and directories at the path.
*/
Future<String> rm(String path) {
  return FileSystemEntity.type(path)
    .then((FileSystemEntityType type) {
      switch(type) {
        case FileSystemEntityType.FILE:
          return new File(path).delete().then((_) => path);
        case FileSystemEntityType.DIRECTORY:
          return new Directory(path).delete(recursive: true).then((_) => path);
        case FileSystemEntityType.LINK:
          return new Link(path).delete().then((_) => path);
      }
      return path;
    });
}
