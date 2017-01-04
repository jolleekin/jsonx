import 'package:test/test.dart';

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

  static const one = const Enum._(1);
  static const two = const Enum._(2);
}

enum Color { blue, green, red }

class A {
  // Ignored by the jsonx encoder.
  @jsonIgnore
  int a1;

  int a2;

  // Ignored because of readonly.
  final int a3 = 3;

  // Ignored because of readonly.
  int get a4 => 4;
}

@jsonObject
class B {
  @jsonProperty
  int b1;

  // Ignored by the jsonx encoder.
  int b2;
}

class C {
  @jsonIgnoreNull
  int c1;

  int c2;
}

@jsonObject
class D {
  @jsonProperty
  @jsonIgnoreNull
  int d1;

  @jsonIgnoreNull
  int d2;
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

  var encodedAddress =
      '{'
        '"line1":"123 JACKSON ST",'
        '"line2":null,'
        '"city":"DA NANG",'
        '"state":null,'
        '"country":"VIETNAM"'
      '}';

  var expectedWithoutIndent =
      '{'
        '"key":"parent",'
        '"name":"parent",'
        '"birthday":"1970-06-01 00:00:00.000",'
        '"address":$encodedAddress,'
        '"children":[{'
          '"key":"child 1",'
          '"name":"child 1",'
          '"birthday":"2000-04-01 00:00:00.000",'
          '"address":$encodedAddress,'
          '"children":null'
        '},{'
          '"key":"child 2",'
          '"name":"child 2",'
          '"birthday":"2001-05-01 00:00:00.000",'
          '"address":$encodedAddress,'
          '"children":null}'
        ']'
      '}';

  var expectedWithIndent = '''
{
  "key": "parent",
  "name": "parent",
  "birthday": "1970-06-01 00:00:00.000",
  "address": {
    "line1": "123 JACKSON ST",
    "line2": null,
    "city": "DA NANG",
    "state": null,
    "country": "VIETNAM"
  },
  "children": [
    {
      "key": "child 1",
      "name": "child 1",
      "birthday": "2000-04-01 00:00:00.000",
      "address": {
        "line1": "123 JACKSON ST",
        "line2": null,
        "city": "DA NANG",
        "state": null,
        "country": "VIETNAM"
      },
      "children": null
    },
    {
      "key": "child 2",
      "name": "child 2",
      "birthday": "2001-05-01 00:00:00.000",
      "address": {
        "line1": "123 JACKSON ST",
        "line2": null,
        "city": "DA NANG",
        "state": null,
        "country": "VIETNAM"
      },
      "children": null
    }
  ]
}''';

  test('encode with indent', () {
    const indent = '  ';
    var s00 = encode(parent1, indent: indent);
    var s01 = const JsonxEncoder<Person>(indent: indent).convert(parent1);
    var s02 = new JsonxCodec<Person>(indent: indent).encode(parent1);
    expect(s00, equals(s01));
    expect(s00, equals(s02));
    expect(s00, equals(expectedWithIndent));
  });

  test('encode', () {
    var s1 = encode(parent1);
    expect(s1, equals(expectedWithoutIndent));
  });

  test('decode', () {
    var parent2 = decode(encode(parent1), type: Person) as Person;
    expect(parent2.name, equals('parent'));
    expect(parent2.birthday.year, equals(1970));
    expect(parent2.children.first.name, equals('child 1'));
    expect(parent2.children.first.birthday.month, equals(4));
    expect(parent2.children.first.address.country, equals('VIETNAM'));
  });

  test('decode to generics', () {
    List<String> list = decode('["green", "yellow", "orange"]',
        type: const TypeHelper<List<String>>().type);
    expect(list.length, equals(3));
    expect(list[1], equals('yellow'));
  });

  test('JsonxCodec', () {
    var codec = new JsonxCodec<Person>();
    expect(codec.encode(parent1), equals(expectedWithoutIndent));
    expect(codec.decode(encode(parent1)).address.country,
        equals('VIETNAM'));
  });

  test('Custom jsonToObject/objectToJson', () {
    // Register a converter that converts an [Enum] into an integer.
    objectToJsons[Enum] = (Enum input) => input._id;

    // Register a converter that converts an integer into an [Enum].
    jsonToObjects[Enum] = (int input) {
      if (input == 1) return Enum.one;
      if (input == 2) return Enum.two;
      throw new ArgumentError('Unknown enum value [$input]');
    };

    expect(encode(Enum.one), equals('1'));
    expect(decode('1', type: Enum), equals(Enum.one));
  });

  test('Annotations', () {
    var a = new A()
      ..a1 = 10
      ..a2 = 5;
    expect(encode(a), equals('{"a2":5}'));

    var b = new B()
      ..b1 = 10
      ..b2 = 5;
    expect(encode(b), equals('{"b1":10}'));
  });

  test('Property name conversion', () {
    var a = new A()
      ..a1 = 10
      ..a2 = 5;

    propertyNameEncoder = toPascalCase;
    propertyNameDecoder = toCamelCase;

    expect(encode(a), equals('{"A2":5}'));
    expect(decode('{"A2":5}', type: A).a2, equals(5));

    propertyNameDecoder = identityFunction;
    propertyNameEncoder = identityFunction;
  });

  test('Enums', () {
    expect(encode(Color.red), equals('2'));
    expect(decode('1', type: Color), equals(Color.green));
  });

  test('ignoreNull without jsonObject', () {
    var c = new C()
      ..c1 = null
      ..c2 = null;
    expect(encode(c).contains("c1"), isFalse);
    expect(encode(c).contains("c2"), isTrue);
  });

  test('ignoreNull with jsonObject', () {
    var d = new D()
      ..d1 = null
      ..d2 = 5;
    expect(encode(d).contains("d1"), isFalse);
    expect(encode(d).contains("d2"), isFalse);
  });

  test('Sets', () {
    var set = new Set.from([1, 1, 1, 2, 3]);
    expect(encode(set), equals('[1,2,3]'));
    var type = new TypeHelper<Set<int>>().type;
    expect(decode('[1,1,1,2,3]', type: type), orderedEquals([1, 2, 3]));
  });
}
