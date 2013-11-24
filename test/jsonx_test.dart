import '../lib/jsonx.dart';

class KeyedItem {
  String key;
}

class Person extends KeyedItem {
  String name;
  int age;
  List<Person> children;
}

class Parser<T> {
  final _listType = <T>[].runtimeType;

  T parse(String text) => decode(text, type: T);

  List<T> parseList(String text) => decode(text, type: _listType);
}

main() {
  var c1 = new Person()
      ..key = 'child 1'
      ..name = 'child 1'
      ..age = 5;

  var c2 = new Person()
      ..key = 'child 2'
      ..name = 'child 2'
      ..age = 8;

  var p1 = new Person()
      ..key = 'parent'
      ..name = 'parent'
      ..age = 40
      ..children = [c1, c2];

  var s1 = encode(p1);
  var expected =
      '{"key":"parent","name":"parent","age":40,"children":[' +
      '{"key":"child 1","name":"child 1","age":5,"children":null},' +
      '{"key":"child 2","name":"child 2","age":8,"children":null}]}';
  assert(s1 == expected);
  print('[encode - object] passed');

  //

  Person p2 = decode(s1, type: Person);
  assert(p2.name == 'parent');
  assert(p2.children.first.name == 'child 1');
  print('[decode - object] passed');
  //

  var s2 = encode(p2);
  assert(s2 == expected);
  print('[encode - object] passed');

  //

  List<String> list = decode('["green", "yellow", "orange"]',
      type: <String>[].runtimeType);
  assert(list.length == 3);
  assert(list[1] == 'yellow');

  //

  var a = new Parser<Person>();

  var p = a.parse('{"key":"1","name":"Tom","age":5}');
  assert(p.name == 'Tom');

  var l = a.parseList('[{"key":"1","name":"Tom","age":5}]');
  assert(l.first.age == 5);

  print('[decode - generics] passed');
}