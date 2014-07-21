# Beyond Primitives, Lists, and Maps

**jsonx** is an extended JSON library that supports the encoding and decoding of
arbitrary objects. **jsonx** can decode a JSON string into a strongly typed object
which gets **type checking** and **code autocompletion** support, or encode an
arbitrary object into a JSON string.

# Decode a JSON String
```` dart
decode(String text, {reviver(key, value), Type type});
````
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
```` dart
// Members from superclasses are decoded also.
class KeyedItem {
  String key;
}

class Person extends KeyedItem {
  String name;
  int age;
}

Person p = decode('{ "key": "1", "name": "Tom", "age": 5 }', type: Person);
print(p.key);   // 1
print(p.name);  // Tom

List<int> list = decode('[1,2,3]', type: <int>[].runtimeType);
print(list[1]); // 2
````
# Encode an Object
```` dart
String encode(object)
````
Encodes `object` as a JSON string.

The encoding happens as below:

1. Tries to encode `object` directly
2. If (1) fails, tries to call `object.toJson()` to convert `object` into
an encodable value
3. If (2) fails, tries to use mirrors to convert `object` into en encodable value

Example:
```` dart
// Members from superclasses are encoded also.
class KeyedItem {
  String key;
}

class Person extends KeyedItem {
  String name;
  int age;
}

var p = new Person()
    ..key = '2'
    ..name = 'Jerry'
    ..age = 5;
print(encode(p)); // {"key":"2","name":"Jerry","age":5}
````
# Use the Codec API

The top level methods `decode` and `encode` provide a quick and handy way to do
decoding and encoding. However, when there is a lot of encoding/decoding for a
specific type, the following Codec API may be a better choice.
```` dart
/**
 * This class converts JSON strings into objects of type [T].
 */
class JsonxDecoder<T> extends Converter<String, T> {

  T convert(String input);
}

/**
 * This class converts objects of type [T] into JSON strings.
 */
class JsonxEncoder<T> extends Converter<T, String> {

  String convert(T input);
}

/**
 * [JsonxCodec] encodes objects of type [T] to JSON strings and decodes JSON
 * strings to objects of type [T].
 */
class JsonxCodec<T> extends Codec<T, String> {

  String encode(T input);
  T decode(String encoded);

  JsonxDecoder<T> get decoder;
  JsonxEncoder<T> get encoder;
}
````
Example:
```` dart
var codec = new JsonxCodec<Person>();
var p = codec.decode('{ "key": "1", "name": "Tom", "age": 5 }');
var s = codec.encode(p);
````
# Work with generics
Dart doesn't allow generic type literals to be passed as arguments, so the
library exposes the following helper class to help user deal with that.
```` dart
/**
 * A helper class to retrieve the runtime type of a generic type.
 *
 * For example, to retrive the type of `List<int>`, use
 *     const TypeHelper<List<int>>().type
 */
class TypeHelper<T> {
  Type get type => T;

  const TypeHelper();
}
````
Example:
```` dart
List<String> list = decode('["green", "yellow", "orange"]',
    type: const TypeHelper<List<String>>().type);
````
# Customize the Behavior of Encoding and Decoding

Starting from version 1.2.0, users can customize the behavior of encoding
and decoding to further extend the capability of the library. But before jumping
into that topic, let's understand how an object is encoded/decoded at a high level.

                _objectToJson               JSON.encode
    Dart object --------------> Json object --------------> Json string

                _jsonToObject               JSON.decode
    Dart object <-------------- Json object <-------------- Json string

    Note: Json objects are objects that consist of only `null`, `num`, `bool`,
    `String`, `List`, and `Map`.

Before version 1.2.0, the behavior of `_objectToJson` and `_jsonToObject`
methods is fixed and cannot be customized by users. However, starting from
this version, customization is made possible thanks to the following two top
level objects.
```` dart
typedef ConvertFunction(input);

/**
 * This object allows users to provide their own json-to-object converters for
 * specific types.
 *
 * By default, this object specifies a converter for [DateTime], which can be
 * overwritten by users.
 *
 * NOTE:
 * Keys must not be [num], [int], [double], [bool], [String], [List], or [Map].
 */
final Map<Type, ConvertFunction> jsonToObjects = <Type, ConvertFunction>{
  DateTime: DateTime.parse
};

/**
 * This object allows users to provide their own object-to-json converters for
 * specific types.
 *
 * By default, this object specifies a converter for [DateTime], which can be
 * overwritten by users.
 *
 * NOTE:
 * Keys must not be [num], [int], [double], [bool], [String], [List], or [Map].
 */
final Map<Type, ConvertFunction> objectToJsons = <Type, ConvertFunction>{
  DateTime: (input) => input.toString()
};
````
Example
```` dart
class Enum {
  final int _id;

  const Enum._(this._id);

  static const ONE = const Enum._(1);
  static const TWO = const Enum._(2);
}

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
````

# Annotations
- `@jsonIgnore`: used against a field or property, instructing the jsonx encoder
  to ignore that field or property
- `@jsonObject`: used against a class, instructing the jsonx encoder to encode
  only fields and properties marked with the annotation '@jsonProperty'
- `@jsonProperty`: used against a field or property, instructing the jsonx
  encoder to encode that field or property 

Example
```` dart
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

var a = new A()
    ..a1 = 10
    ..a2 = 5;
assert(encode(a) == '{"a2":5}');

var b = new B()
    ..b1 = 10
    ..b2 = 5;
assert(encode(b) == '{"b1":10}');
````
