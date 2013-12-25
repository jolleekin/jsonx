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

# Encode an Object

    String encode(object)

Encodes `object` as a JSON string.

The encoding happens as below:

1. Tries to encode `object` directly
2. If (1) fails, tries to call `object.toJson()` to convert `object` into
an encodable value
3. If (2) fails, tries to use mirrors to convert `object` into en encodable value

Example:

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

# Using the Codec API

The top level methods `decode` and `encode` provide a quick and handy way to do
decoding and encoding. However, when there is a lot of encoding/decoding for a
specific type, the following Codec API may be a better choice.

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

Example:

    var codec = new JsonxCodec<Person>();
    var p = codec.decode('{ "key": "1", "name": "Tom", "age": 5 }');
    var s = codec.encode(p);