library TestLibray;

import 'package:jsonx/jsonx.dart';
import 'dart:mirrors';

import 'package:unittest/unittest.dart';

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

  var addressEncoded = '{' '"line1":"123 JACKSON ST",' '"line2":null,' '"city":"DA NANG",' '"state":null,' '"country":"VIETNAM"' '}';

  var expectedWithoutIndent = '{' '"key":"parent",' '"name":"parent",' '"birthday":"1970-06-01 00:00:00.000",' '"address":$addressEncoded,' '"children":[{' '"key":"child 1",' '"name":"child 1",' '"birthday":"2000-04-01 00:00:00.000",' '"address":$addressEncoded,' '"children":null' '},{' '"key":"child 2",' '"name":"child 2",' '"birthday":"2001-05-01 00:00:00.000",' '"address":$addressEncoded,' '"children":null}' ']' '}';

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
    const INDENT = '  ';
    var s00 = encode(parent1, indent: INDENT);
    var s01 = const JsonxEncoder<Person>(indent: INDENT).convert(parent1);
    var s02 = new JsonxCodec<Person>(indent: INDENT).encode(parent1);
    expect(s00, equals(s01));
    expect(s00, equals(s02));
    expect(s00, equalsIgnoringCase(expectedWithIndent));
  });

  test('encode', () {
    var s1 = encode(parent1);
    expect(s1, equalsIgnoringCase(expectedWithoutIndent));
  });

  test('decode', () {
    Person parent2 = decode(encode(parent1), type: Person);
    expect(parent2.name, equalsIgnoringCase('parent'));
    expect(parent2.birthday.year, equals(1970));
    expect(parent2.children.first.name, equalsIgnoringCase('child 1'));
    expect(parent2.children.first.birthday.month, equals(4));
    expect(parent2.children.first.address.country, equalsIgnoringCase('VIETNAM'));
  });

  test('decode to generics', () {
    List<String> list = decode('["green", "yellow", "orange"]', type: const TypeHelper<List<String>>().type);
    expect(list.length, equals(3));
    expect(list[1], equals('yellow'));
  });

  test('JsonxCodec', () {
    var codec = new JsonxCodec<Person>();
    expect(codec.encode(parent1), equalsIgnoringCase(expectedWithoutIndent));
    expect(codec.decode(encode(parent1)).address.country, equalsIgnoringCase('VIETNAM'));
  });

  test('Custom jsonToObject/objectToJson', () {
    // Register a converter that converts an [Enum] into an integer.
    objectToJsons[Enum] = (Enum input) => input._id;

    // Register a converter that converts an integer into an [Enum].
    jsonToObjects[Enum] = (int input) {
      if (input == 1) return Enum.ONE;
      if (input == 2) return Enum.TWO;
      throw new ArgumentError('Unknown enum value [$input]');
    };

    expect(encode(Enum.ONE), equals('1'));
    expect(decode('1', type: Enum), equals(Enum.ONE));
  });

  test('Annotations', () {
    var a = new A()
        ..a1 = 10
        ..a2 = 5;
    expect(encode(a), equalsIgnoringCase('{"a2":5}'));

    var b = new B()
        ..b1 = 10
        ..b2 = 5;
    expect(encode(b), equalsIgnoringCase('{"b1":10}'));
  });

  test('Property name conversion', () {
    var a = new A()
        ..a1 = 10
        ..a2 = 5;

    propertyNameEncoder = toPascalCase;
    propertyNameDecoder = toCamelCase;

    expect(encode(a), equalsIgnoringCase('{"A2":5}'));
    expect(decode('{"A2":5}', type: A).a2, equals(5));
  });

  test('For field type that is sub type of instance type, encodes and decodes correctly',(){
    var parent = new Parent()..child = new ConcreteChild1();

    jsonxUseTypeInformation = true;

    var encodeResult = encode(parent);
    var decodeResult = decode(encodeResult, type: Parent) as Parent;

    expect(decodeResult.child, new isInstanceOf<ConcreteChild1>());
  });


  test('For property with a list of base type and contents of concrete types, encodes and decodes list correctly', () {

    jsonxUseTypeInformation = true;

    var list = new List<Child>()..add(new ConcreteChild1());

    var encodeResult = encode(list);
    var decodeResult = decode(encodeResult, type: new TypeHelper<List<Child>>().type);

    expect(decodeResult[0], new isInstanceOf<ConcreteChild1>());
  });

}

class Parent{
  Child child;
}

abstract class Child{

}

class ConcreteChild1 extends Child{
  String wooHoo;
}
