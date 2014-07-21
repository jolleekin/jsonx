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
  final _decoder = new JsonxDecoder<T>();
  final _encoder = new JsonxEncoder<T>();

  JsonxDecoder<T> get decoder => _decoder;
  JsonxEncoder<T> get encoder => _encoder;
}

/**
 * This class converts JSON strings into objects of type [T].
 */
class JsonxDecoder<T> extends Converter<String, T> {
  T convert(String input) => decode(input, type: T);
}

/**
 * This class converts objects of type [T] into JSON strings.
 */
class JsonxEncoder<T> extends Converter<T, String> {
  String convert(T input) => encode(input);
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
 * decoded. Since Dart doesn't allow passing a generic type as an argument, one must
 * create an instance of that generic type and pass the instance's runtimeType
 * as the value of [type].
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
 * The encoding happens as below:
 * 1. Tries to encode [object] directly
 * 2. If (1) fails, tries to call [object.toJson()] to convert [object] into
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
 *     print(encode(p));
 */
String encode(object) => _ENCODER.convert(object);



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
    // TODO: Consider using [mirror.instanceMembers].
    var setters = _getPublicSetters(mirror);

    for (var key in json.keys) {
      var name = new Symbol(key);
      var decl = setters[name];
      if (decl != null) {
        type = decl.type;
      } else {
        decl = setters[new Symbol('$key=')];
        if (decl != null) {
          type = decl.parameters.first.type;
        } else {
          continue;
        }
      }
      instance.setField(name, _jsonToObject(json[key], type));
    }
  }
  return reflectee;
}

final _objectMirror = reflectClass(Object);

final _publicSetters = <ClassMirror, Map<Symbol, DeclarationMirror>> {};

/**
 * Returns a map of public setters, including fields, of an instance of the
 * class specified by [m].
 *
 * The map includes setters that are inherited as well as those introduced by
 * the class itself.
 */
Map<Symbol, DeclarationMirror> _getPublicSetters(ClassMirror m) {
  var r = _publicSetters[m];
  if (r == null) {
    r = <Symbol, DeclarationMirror> {};
    if (m != _objectMirror) {
      r.addAll(_getPublicSetters(m.superclass));
      m.declarations.forEach((k, v) {
        if (_isPublicSetter(v)) r[k] = v;
      });
    }
  }
  _publicSetters[m] = r;
  return r;
}

final _publicGetters = <ClassMirror, Map<Symbol, DeclarationMirror>> {};

/**
 * Returns a map of public getters, including fields, of an instance of the
 * class specified by [m].
 *
 * The map includes getters that are inherited as well as those introduced by
 * the class itself.
 */
Map<Symbol, DeclarationMirror> _getPublicGetters(ClassMirror m) {
  var r = _publicGetters[m];
  if (r == null) {
    r = <Symbol, DeclarationMirror> {};
    if (m != _objectMirror) {
      r.addAll(_getPublicGetters(m.superclass));
      m.declarations.forEach((k, v) {
        if (_isPublicGetter(v)) r[k] = v;
      });
    }
  }
  _publicGetters[m] = r;
  return r;
}

/**
 * Tests if [v] is a public setter or field.
 */
bool _isPublicSetter(DeclarationMirror v) {
  return (v is VariableMirror && !v.isStatic && !v.isPrivate && !v.isFinal) ||
         (v is MethodMirror && !v.isStatic && !v.isPrivate && v.isSetter);
}

/**
 * Tests if [v] is a public getter or field.
 */
bool _isPublicGetter(DeclarationMirror v) {
  return (v is VariableMirror && !v.isStatic && !v.isPrivate) ||
         (v is MethodMirror && !v.isStatic && !v.isPrivate && v.isGetter);
}

bool _isPrimitive(v) => v is num || v is bool || v is String;

/**
 * Tests if [mirror] has a constant annotation which equals [annotation].
 */
bool _hasAnnotation(DeclarationMirror mirror, Object annotation) {
  for (var meta in mirror.metadata) {
    if (meta.reflectee == annotation) return true;
  }
  return false;
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
  var getters = _getPublicGetters(instanceMirror.type);
  getters.forEach((k, v) {
    if (!optIn && _hasAnnotation(v, jsonIgnore)) return;
    if (optIn && !_hasAnnotation(v, jsonProperty)) return;
    var name = MirrorSystem.getName(k);
    var value = instanceMirror.getField(k).reflectee;
    map[name] = __objectToJson(value);
  });

  return map;
}
