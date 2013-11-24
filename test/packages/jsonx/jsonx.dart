/**
 * An extended JSON library that supports the encoding and decoding of arbitrary
 * objects.
 */
library jsonx;

import 'dart:mirrors';
import 'dart:convert' show JSON, JsonEncoder;

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
// TODO: consider caching mirrors on [type].
decode(String text, {reviver(key, value), Type type}) {
  var json = JSON.decode(text, reviver: reviver);
  if (type == null) return json;
  return _jsonToObject(json, reflectType(type));
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

const _EMTPY_SYMBOL = const Symbol('');

_jsonToObject(json, mirror) {
  if (_isPrimitive(json)) return json;

  TypeMirror type;

  if (json is List) {
    var result = [];
    type = mirror.typeArguments.single;
    for (var value in json) {
      result.add(_jsonToObject(value, type));
    }
    return result;
  }

  var instanceMirror = mirror.newInstance(_EMTPY_SYMBOL, []);

  if (instanceMirror.reflectee is Map) {
    var result = {};
    type = mirror.typeArguments.last;
    for (var key in json.keys) {
      result[key] = _jsonToObject(json[key], type);
    }
    return result;
  }

  var setters = _getPublicSetters(mirror);

  for (var key in json.keys) {
    var name = new Symbol(key);

//    See https://code.google.com/p/dart/issues/detail?id=15281
//    var member = mirror.instanceMembers[name];
//    if (!_isPublicSetter(member)) continue;

    var member = setters[name];
    if (member != null) {
      type = member.type;
    } else {
      var n = new Symbol('$key=');
      member = setters[n];
      if (member != null) {
        type = member.parameters.first.type;
      } else {
        continue;
      }
    }

    instanceMirror.setField(name, _jsonToObject(json[key], type));
  }
  return instanceMirror.reflectee;
}

final _objectMirror = reflectClass(Object);

final _publicSetters = <ClassMirror, Map<Symbol, DeclarationMirror>>{};

/**
 * Returns a map of public setters, including implicit setters, of an instance
 * of the class specified by [m].
 *
 * The map includes setters that are inherited as well as those introduced by
 * the class itself.
 */
Map<Symbol, DeclarationMirror> _getPublicSetters(ClassMirror m) {
  var r = _publicSetters[m];
  if (r == null) {
    r = <Symbol, DeclarationMirror>{};
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

final _publicGetters = <ClassMirror, Map<Symbol, DeclarationMirror>>{};

/**
 * Returns a map of public getters, including implicit getters, of an instance
 * of the class specified by [m].
 *
 * The map includes getters that are inherited as well as those introduced by
 * the class itself.
 */
Map<Symbol, DeclarationMirror> _getPublicGetters(ClassMirror m) {
  var r = _publicGetters[m];
  if (r == null) {
    r = <Symbol, DeclarationMirror>{};
    if (m != _objectMirror) {
      r.addAll(_getPublicSetters(m.superclass));
      m.declarations.forEach((k, v) {
        if (_isPublicGetter(v)) r[k] = v;
      });
    }
  }
  _publicGetters[m] = r;
  return r;
}

bool _isPublicVariable(DeclarationMirror v) {
  return v is VariableMirror && !v.isStatic && !v.isPrivate && !v.isFinal;
  // TODO: Add isConst when the bug is fixed.
}

bool _isPublicSetter(DeclarationMirror v) {
  return (v is VariableMirror && !v.isStatic && !v.isPrivate && !v.isFinal) ||
         (v is MethodMirror && !v.isStatic && !v.isPrivate && v.isSetter);
}

bool _isPublicGetter(DeclarationMirror v) {
  return (v is VariableMirror && !v.isStatic && !v.isPrivate) ||
         (v is MethodMirror && !v.isStatic && !v.isPrivate && v.isGetter);
}

bool _isPrimitive(v) {
  return v is num || v is bool || v is String || v == null;
}

const _ENCODER = const JsonEncoder(_toEncodable);

_toEncodable(object) {
  try {
    return object.toJson();
  } catch (_) {
    return __toEncodable(object);
  }
}

__toEncodable(object) {
  if (_isPrimitive(object)) return object;

  if (object is List) {
    var list = [];
    for (var e in object) {
      list.add(__toEncodable(e));
    }
    return list;
  }

  var map = {};

  if (object is Map) {
    for (var key in object.keys) {
      map[key] = __toEncodable(object[key]);
    }
    return map;
  }

  var instanceMirror = reflect(object);

  var getters = _getPublicGetters(instanceMirror.type);
  for (var k in getters.keys) {
    var name = MirrorSystem.getName(k);
    var value = instanceMirror.getField(k).reflectee;
    map[name] = __toEncodable(value);
  }

  return map;
}