import '../lib/jsonx.dart';

class KeyedItem {
  String key;
}

class Address {
  String line1;
  String line2;
  String city;
  String state;
  String country;
}

class Person extends KeyedItem {
  String name;
  DateTime birthday;
  Address address;
  List<Person> children;
}

class Enum {
  final int _id;

  const Enum._(this._id);

  static const ONE = const Enum._(1);
  static const TWO = const Enum._(2);
}

class A {
  // Ignored by the jsonx encoder.
  @jsonIgnore
  int a1;

  int a2;
}

@jsonObject
class B {
  @jsonProperty
  int b1;

  // Ignored by the jsonx encoder.
  int b2;
}

main() {
  // ------------ set up --------------

  var address = new Address()
      ..line1 = '123 JACKSON ST'
      ..city = 'DA NANG'
      ..country = 'VIETNAM';

  var child1 = new Person()
      ..key = 'child 1'
      ..name = 'child 1'
      ..birthday = new DateTime(2000, 4, 1)
      ..address = address;

  var child2 = new Person()
      ..key = 'child 2'
      ..name = 'child 2'
      ..birthday = new DateTime(2001, 5, 1)
      ..address = address;

  var parent1 = new Person()
      ..key = 'parent'
      ..name = 'parent'
      ..birthday = new DateTime(1970, 6, 1)
      ..address = address
      ..children = [child1, child2];

  var addressEncoded = '{'
      '"line1":"123 JACKSON ST",'
      '"line2":null,'
      '"city":"DA NANG",'
      '"state":null,'
      '"country":"VIETNAM"'
    '}';

  var expected = '{'
      '"key":"parent",'
      '"name":"parent",'
      '"birthday":"1970-06-01 00:00:00.000",'
      '"address":$addressEncoded,'
      '"children":[{'
        '"key":"child 1",'
        '"name":"child 1",'
        '"birthday":"2000-04-01 00:00:00.000",'
        '"address":$addressEncoded,'
        '"children":null'
      '},{'
        '"key":"child 2",'
        '"name":"child 2",'
        '"birthday":"2001-05-01 00:00:00.000",'
        '"address":$addressEncoded,'
        '"children":null}'
      ']'
    '}';

  //------------ encode --------------

  var s1 = encode(parent1);

  assert(s1 == expected);

  //------------ decode --------------

  Person parent2 = decode(s1, type: Person);
  assert(parent2.name == 'parent');
  assert(parent2.birthday.year == 1970);
  assert(parent2.children.first.name == 'child 1');
  assert(parent2.children.first.birthday.month == 4);
  assert(parent2.children.first.address.country == 'VIETNAM');

  //------------ re-encode --------------

  var s2 = encode(parent2);
  assert(s2 == expected);

  //----------- decode to generics ---------------

  List<String> list = decode('["green", "yellow", "orange"]',
      type: const TypeHelper<List<String>>().type);
  assert(list.length == 3);
  assert(list[1] == 'yellow');

  //------------ JsonxCodec --------------

  var codec = new JsonxCodec<Person>();
  assert(codec.encode(parent1) == expected);
  assert(codec.decode(s1).address.country == 'VIETNAM');

  //------------ Custom jsonToObject/objectToJson --------------

  // Register a converter that converts an [Enum] into an integer.
  objectToJsons[Enum] = (Enum input) => input._id;

  // Register a converter that converts an integer into an [Enum].
  jsonToObjects[Enum] = (int input) {
    if (input == 1) return Enum.ONE;
    if (input == 2) return Enum.TWO;
    throw new ArgumentError('Unknown enum value [$input]');
  };

  assert(encode(Enum.ONE) == '1');
  assert(decode('1', type: Enum) == Enum.ONE);

  //------------ Annotations --------------

  var a = new A()
      ..a1 = 10
      ..a2 = 5;
  assert(encode(a) == '{"a2":5}');

  var b = new B()
      ..b1 = 10
      ..b2 = 5;
  assert(encode(b) == '{"b1":10}');
}
