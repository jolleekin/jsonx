# Beyond Primitives, Lists, and Maps

**jsonx** is an extended JSON library that supports the encoding and decoding of
arbitrary objects. **jsonx** can decode a JSON string into a strongly typed object
which gets **type checking** and **code autocompletion** support, or encode an
arbitrary object into a JSON string.

# Decode a JSON String

	decode(String text, {reviver(key, value), Type type});

Decodes the JSON string `text` given the optional type `type`.

The optional `reviver` function is called once for each object or list
property that has been parsed during decoding. The `key` argument is either
the integer list index for a list property, the map string for object
properties, or `null` for the final result.

The default `reviver` (when not provided) is the identity function.

The optional `type` parameter specifies the type to which `text` should be
decoded. Since Dart doesn't allow passing a generic type as an argument, one must
create an instance of that generic type and pass the instance's runtimeType
as the value of `type`.

If `type` is omitted, this method is equivalent to `JSON.decode` in
**dart:convert** library.

Example:

    class Person {
      String name;
      int age;
    }

    Person p = decode('{ "name": "Tom", "age": 20 }', type: Person);
    print(p.name); // Tom

    List<int> list = decode('[1,2,3]', type: <int>[].runtimeType);
    print(list[1]); // 2

# Encode an Object

	String encode(object)

Encodes `object` as a JSON string.

The encoding happens as below:

1. Tries to encode `object` directly
2. If (1) fails, tries to call `object.toJson()` to convert `object` into
an encodable value
3. If (2) fails, tries to use mirrors to convert `object` into en encodable value

Example:

    class Person {
      Person(this.name, this.age);
      String name;
      int age;
    }

    var p = new Person('Jerry', 20);
    print(encode(p)); // {"name":"Jerry","age":20}