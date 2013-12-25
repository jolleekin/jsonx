import '../lib/jsonx.dart';

class KeyedItem {
  String key;
}

class Contact {
  String addressLine1;
  String addressLine2;
  String city;
  String state;
  String country;
}

class Person extends KeyedItem {
  String name;
  int age;
  Contact contact;
  List<Person> children;
}

main() {
  var contact = new Contact()
      ..addressLine1 = '123 JACKSON ST'
      ..city = 'DA NANG'
      ..country = 'VIETNAM';

  var child1 = new Person()
      ..key = 'child 1'
      ..name = 'child 1'
      ..age = 5
      ..contact = contact;

  var child2 = new Person()
      ..key = 'child 2'
      ..name = 'child 2'
      ..age = 8
      ..contact = contact;

  var parent1 = new Person()
      ..key = 'parent'
      ..name = 'parent'
      ..age = 40
      ..contact = contact
      ..children = [child1, child2];

  var contactEncoded = '{'
      '"addressLine1":"123 JACKSON ST",'
      '"addressLine2":null,'
      '"city":"DA NANG",'
      '"state":null,'
      '"country":"VIETNAM"'
    '}';

  var expected = '{'
      '"key":"parent","name":"parent","age":40,"contact":$contactEncoded,'
      '"children":['
        '{"key":"child 1","name":"child 1","age":5,"contact":$contactEncoded,"children":null},'
        '{"key":"child 2","name":"child 2","age":8,"contact":$contactEncoded,"children":null}'
      ']'
    '}';

  //------------ encode --------------

  var s1 = encode(parent1);

  assert(s1 == expected);

  //------------ decode --------------

  Person parent2 = decode(s1, type: Person);
  assert(parent2.name == 'parent');
  assert(parent2.children.first.name == 'child 1');
  assert(parent2.children.first.contact.country == 'VIETNAM');

  //------------ re-encode --------------

  var s2 = encode(parent2);
  assert(s2 == expected);

  //----------- decode to generics ---------------

  List<String> list = decode('["green", "yellow", "orange"]',
      type: <String>[].runtimeType);
  assert(list.length == 3);
  assert(list[1] == 'yellow');

  //------------ JsonxCodec --------------

  var codec = new JsonxCodec<Person>();
  assert(codec.encode(parent1) == expected);
  assert(codec.decode(s1).contact.country == 'VIETNAM');
}