/**
 * An extended JSON library that supports the encoding and decoding of arbitrary
 * objects.
 */
library jsonx;

import 'dart:mirrors';
import 'dart:convert';

class _JsonObject {
  const _JsonObject();
}

class _JsonIgnore {
  const _JsonIgnore();
}

class _JsonProperty {
  const _JsonProperty();
}

/**
 * Marking a class with the annotation '@jsonObject' instructs the jsonx
 * encoder to encode only fields and properties marked with the annotation
 * '@jsonProperty'.
 */
const Object jsonObject = const _JsonObject();

/**
 * Marking a field or property with the annotation '@jsonIgnore' instructs the
 * jsonx encoder not to encode that field or property.
 *
 * This annotation only has effects if the corresponding class is *NOT*
 * annotated with '@jsonObject'.
 */
const Object jsonIgnore = const _JsonIgnore();

/**
 * Marking a field or property with the annotation '@jsonProperty' instructs the
 * jsonx encoder to encode that field or property and ignore fields and
 * properties without that annotation.
 *
 * This annotation only has effects if the corresponding class is annotated with
 * '@jsonObject'.
 */
const Object jsonProperty = const _JsonProperty();

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

/**
 * [JsonxCodec] encodes objects of type [T] to JSON strings and decodes JSON
 * strings to objects of type [T].
 */
class JsonxCodec<T> extends Codec<T, String> {
  final JsonxDecoder<T> _decoder;
  final JsonxEncoder<T> _encoder;

  /**
   * Creates a [JsonxCodec] with the given indent and reviver.
   *
   * [indent] is used during encoding to produce a multi-line output. If `null`,
   * the output is encoded as a single line.
   *
   * The [reviver] function is called once for each object or list
   * property that has been parsed during decoding. The `key` argument is either
   * the integer list index for a list property, the map string for object
   * properties, or `null` for the final result.
   *
   * The default [reviver] (when not provided) is the identity function.
   */
  JsonxCodec({String indent, reviver(key, value)})
      : _decoder = new JsonxDecoder<T>(reviver: reviver),
        _encoder = new JsonxEncoder<T>(indent: indent);

  JsonxDecoder<T> get decoder => _decoder;
  JsonxEncoder<T> get encoder => _encoder;
}

/**
 * This class converts JSON strings into objects of type [T].
 */
class JsonxDecoder<T> extends Converter<String, T> {
  /**
   * Creates a [JsonxDecoder].
   */
  const JsonxDecoder({this.reviver(key, value)});

  /**
   * The reviver function.
   */
  final reviver;

  /**
   * Converts a JSON string into an object of type [T].
   */
  T convert(String input) => decode(input, reviver: reviver, type: T);
}

/**
 * This class converts objects of type [T] into JSON strings.
 */
class JsonxEncoder<T> extends Converter<T, String> {
  /**
   * Creates a [JsonxEncoder].
   *
   * [indent] is used to produce a multi-line output. If `null`, the output is
   * encoded as a single line.
   */
  const JsonxEncoder({String this.indent});

  /**
   * The string used for indention.
   *
   * When generating a multi-line output, this string is inserted once at the
   * beginning of each indented line for each level of indentation.
   *
   * If `null`, the output is encoded as a single line.
   */
  final String indent;

  /**
   * Converts an object of type [T] into a JSON string.
   */
  String convert(T input) => encode(input, indent: indent);
}

/**
 * Decodes the JSON string [text].
 *
 * The optional [reviver] function is called once for each object or list
 * property that has been parsed during decoding. The `key` argument is either
 * the integer list index for a list property, the map string for object
 * properties, or `null` for the final result.
 *
 * The default [reviver] (when not provided) is the identity function.
 *
 * The optional [type] parameter specifies the type to which [text] should be
 * decoded. `type` **must have a default constructor**. To work with generics,
 * use [TypeHelper].
 *
 * If [type] is omitted, this method is equivalent to [JSON.decode] in
 * **dart:convert** library.
 *
 * Example:
 *
 *     class Person {
 *       String name;
 *       int age;
 *     }
 *
 *     Person p = decode('{ "name": "Man", "age": 20 }', type: Person);
 *     print(p.name);
 *
 *     List<int> list = decode('[1,2,3]', type: <int>[].runtimeType);
 */
decode(String text, {reviver(key, value), Type type}) {
  var json = JSON.decode(text, reviver: reviver);
  if (type == null) return json;
  var mirror = _typeMirrors[type];
  if (mirror == null) mirror = _typeMirrors[type] = reflectType(type);
  return _jsonToObject(json, mirror);
}

/**
 * Encodes [object] as a JSON string.
 *
 * [indent] is used to produce a multi-line output. If `null`, the output is
 * encoded as a single line.
 *
 * The encoding happens as below:
 * 1. Tries to encode [object] directly
 * 2. If (1) fails, tries to call [object.toJson] to convert [object] into
 * an encodable value
 * 3. If (2) fails, tries to use mirrors to convert [object] into en encodable
 * value
 *
 * Example:
 *
 *     class Person {
 *       Person(this.name, this.age);
 *       String name;
 *       int age;
 *     }
 *
 *     var p = new Person('kin', 20);
 *     print(encode(p, indent: '  '));
 */
String encode(object, {String indent}) {
  if (indent == null) return _ENCODER.convert(object);
  return new JsonEncoder.withIndent(indent, _objectToJson).convert(object);
}



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
final Map<Type, ConvertFunction> jsonToObjects = <Type, ConvertFunction> {
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
final Map<Type, ConvertFunction> objectToJsons = <Type, ConvertFunction> {
  DateTime: (input) => input.toString()
};

/**
 * A function that returns the argument passed in.
 */
identityFunction(input) => input;

/**
 * Converts a string from PascalCase to camelCase.
 *
 * This function is intended to be used as a value of [propertyNameDecoder].
 */
String toCamelCase(String input) =>
    input[0].toLowerCase() + input.substring(1);

/**
 * Converts a string from camelCase to PascalCase.
 *
 * This function is inntended to be used as a value of [propertyNameEncoder].
 */
String toPascalCase(String input) =>
    input[0].toUpperCase() + input.substring(1);

/**
 * A function that globally controls how a JSON property name is decoded into an
 * object property name.
 *
 * For example, to convert all property names to camelCase during decoding, set
 * this variable to [toCamelCase].
 *
 * By default, this function leaves property names as is.
 */
ConvertFunction propertyNameDecoder = identityFunction;

/**
 * A function that globally controls how an object property name is encoded as
 * a JSON property name.
 *
 * For example, to convert all property names to PascalCase during encoding, set
 * this variable to [toPascalCase].
 *
 * By default, this function leaves property names as is.
 */
ConvertFunction propertyNameEncoder = identityFunction;


final _typeMirrors = <Type, TypeMirror> {};

const _EMTPY_SYMBOL = const Symbol('');

_jsonToObject(json, mirror) {
  if (json == null) return null;

  var convert = jsonToObjects[mirror.reflectedType];
  if (convert != null) return convert(json);

  if (_isPrimitive(json)) return json;

  TypeMirror type;

  // https://code.google.com/p/dart/issues/detail?id=15942
  var instance = mirror.qualifiedName == #dart.core.List ?
      reflect(mirror.newInstance(_EMTPY_SYMBOL, [0]).reflectee.toList()) :
      mirror.newInstance(_EMTPY_SYMBOL, []);
  var reflectee = instance.reflectee;

  if (reflectee is List) {
    type = mirror.typeArguments.single;
    for (var value in json) {
      reflectee.add(_jsonToObject(value, type));
    }
  } else if (reflectee is Map) {
    type = mirror.typeArguments.last;
    for (var key in json.keys) {
      reflectee[key] = _jsonToObject(json[key], type);
    }
  } else {
    var properties = _getPublicReadWriteProperties(mirror);

    for (var key in json.keys) {
      var decodedKey = propertyNameDecoder(key);
      var name = new Symbol(decodedKey);
      var property = properties[name];
      if (property == null) continue;
      instance.setField(name, _jsonToObject(json[key], property.type));
    }
  }
  return reflectee;
}

const _ENCODER = const JsonEncoder(_objectToJson);

_objectToJson(object) {
  try {
    return object.toJson();
  } catch (_) {
    return __objectToJson(object);
  }
}

__objectToJson(object) {
  if (object == null) return null;

  var convert = objectToJsons[object.runtimeType];
  if (convert != null) return convert(object);

  if (_isPrimitive(object)) return object;

  if (object is List) {
    var list = [];
    for (var e in object) {
      list.add(__objectToJson(e));
    }
    return list;
  }

  var map = {};

  if (object is Map) {
    for (var key in object.keys) {
      map[key] = __objectToJson(object[key]);
    }
    return map;
  }

  var instanceMirror = reflect(object);
  var optIn = _hasAnnotation(instanceMirror.type, jsonObject);

  // TODO: Consider using [instanceMirror.type.instanceMembers].
  var properties = _getPublicReadWriteProperties(instanceMirror.type);
  properties.forEach((k, v) {
    if (!optIn && _hasAnnotation(v, jsonIgnore)) return;
    if (optIn && !_hasAnnotation(v, jsonProperty)) return;
    var name = propertyNameEncoder(MirrorSystem.getName(k));
    var value = instanceMirror.getField(k).reflectee;
    map[name] = __objectToJson(value);
  });

  return map;
}

class _Property {
  const _Property(this.name, this.type, this.metadata);

  final Symbol name;
  final TypeMirror type;
  final List<InstanceMirror> metadata;
}

final _objectMirror = reflectClass(Object);

final _publicReadWriteProperties = <ClassMirror, Map<Symbol, _Property>> {};

Map<Symbol, _Property> _getPublicReadWriteProperties(ClassMirror m) {
  var r = _publicReadWriteProperties[m];
  if (r == null) {
    r = <Symbol, _Property> {};
    if (m != _objectMirror) {
      r.addAll(_getPublicReadWriteProperties(m.superclass));
      m.declarations.forEach((k, v) {
        if (_isPublicField(v)) {
          r[k] = new _Property(k, v.type, v.metadata);
        } else if (_isPublicGetter(v) && _hasSetter(m, v)) {
          r[k] = new _Property(k, v.returnType, v.metadata);
        }
      });
    }
  }
  return r;
}

bool _hasSetter(ClassMirror cls, MethodMirror getter) {
  var mirror = cls.declarations[_setterName(getter.simpleName)];
  return mirror is MethodMirror && mirror.isSetter;
}

// https://code.google.com/p/dart/issues/detail?id=10029
Symbol _setterName(Symbol getter) =>
 new Symbol('${MirrorSystem.getName(getter)}=');

bool _isPublicField(DeclarationMirror v) =>
    v is VariableMirror && !v.isStatic && !v.isPrivate && !v.isFinal;

bool _isPublicGetter(DeclarationMirror v) =>
    (v is MethodMirror && !v.isStatic && !v.isPrivate && v.isGetter);

bool _isPrimitive(v) => v is num || v is bool || v is String;

/**
 * Tests if [target] has a constant annotation which equals [annotation].
 *
 * [target] can be a [DeclarationMirror] or [_Property].
 */
bool _hasAnnotation(target, Object annotation) {
  for (var meta in target.metadata) {
    if (meta.reflectee == annotation) return true;
  }
  return false;
}
