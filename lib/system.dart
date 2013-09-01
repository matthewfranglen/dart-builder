library system;
import 'dart:async';
import 'dart:io';

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
    .then((FileSystemEntityType type) => type == FileSystemEntityType.DIRECTORY
                                       ? new Directory(target).list().map((FileSystemEntity entity) => entity.path)
                                       : new StreamController<String>().stream
    );
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
